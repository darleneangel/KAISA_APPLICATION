// Deploy with: supabase functions deploy kaisa-id-ocr
// Set GOOGLE_VISION_API_KEY as Supabase Edge Function secret, NEVER in Flutter.
// Requires a Google Cloud project with Cloud Vision API enabled, suitable billing
// and organizational approval for transferring sensitive ID data to Google Cloud.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (req) => {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json',
  };
  if (req.method === 'OPTIONS') return new Response('', { headers });
  const respond=(code:number, value:unknown)=>new Response(JSON.stringify(value),{status:code,headers});
  if (req.method!=='POST') return respond(405,{error:'Method not allowed'});
  const jwt=req.headers.get('Authorization')?.replace(/^Bearer\s+/i,'');
  if (!jwt) return respond(401,{error:'Authentication required'});
  const sbUrl=Deno.env.get('SUPABASE_URL');
  const serviceKey=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const visionKey=Deno.env.get('GOOGLE_VISION_API_KEY');
  if (!sbUrl||!serviceKey||!visionKey) return respond(503,{error:'Secure OCR integration is not configured'});
  const admin=createClient(sbUrl,serviceKey,{auth:{persistSession:false,autoRefreshToken:false}});
  const {data:{user},error:userError}=await admin.auth.getUser(jwt);
  if(userError||!user) return respond(401,{error:'Unauthorized'});
  let requestId: string;
  try{
    const payload=await req.json();
    requestId=payload.request_id;
    if(typeof requestId!=='string'||!/^[0-9a-f-]{36}$/i.test(requestId))throw Error('Invalid id');
  }catch{return respond(400,{error:'Invalid request identifier'});}
  const {data:record,error:recordError}=await admin.from('kaisa_identity_requests')
    .select('id,user_id,id_path,status').eq('id',requestId).maybeSingle();
  if(recordError||!record||record.user_id!==user.id||record.status!=='pending')
    return respond(403,{error:'Request not accessible'});
  if(!String(record.id_path).startsWith(`${user.id}/`))return respond(403,{error:'Invalid file path'});
  const {data:file,error:fileError}=await admin.storage.from('kaisa-identity').download(record.id_path);
  if(fileError||!file)return respond(404,{error:'Unable to read uploaded document'});
  if(file.size>5*1024*1024)return respond(413,{error:'Document exceeds size policy'});
  // Base64 conversion on server. Do not log document, recognized text, or tokens.
  const bytes=new Uint8Array(await file.arrayBuffer());
  let binary='';
  for(let start=0;start<bytes.length;start+=8192) binary+=String.fromCharCode(...bytes.subarray(start,start+8192));
  const base64=btoa(binary);
  let vision:Response;
  try {
    vision=await fetch('https://vision.googleapis.com/v1/images:annotate',{
      method:'POST',headers:{'Content-Type':'application/json','X-goog-api-key':visionKey},
      body:JSON.stringify({requests:[{image:{content:base64},features:[{type:'TEXT_DETECTION',maxResults:1}]}]})
    });
  }catch{return respond(502,{error:'OCR provider unavailable'});}
  if(!vision.ok)return respond(502,{error:'OCR provider rejected request'});
  const result=await vision.json();
  const raw=String(result.responses?.[0]?.fullTextAnnotation?.text??'');
  // Short admin-only OCR preview; do not treat as verified identity data.
  const excerpt=raw.replace(/\s+/g,' ').trim().slice(0,300);
  const {error:saveError}=await admin.from('kaisa_identity_requests').update({ocr_preview:excerpt})
    .eq('id',requestId).eq('user_id',user.id).eq('status','pending');
  if(saveError)return respond(500,{error:'OCR complete but review text could not be saved'});
  return respond(200,{recognized:excerpt.length>0,message:excerpt?'OCR preview ready for Super Admin review':'No readable text found'});
});
