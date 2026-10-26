import { createClient } from 'npm:@supabase/supabase-js@2';
const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const reply = (status: number, data: Record<string, unknown>) =>
  new Response(JSON.stringify(data), {status,headers:{...cors,'Content-Type':'application/json'}});
Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') return new Response(null,{headers:cors});
  if (req.method !== 'POST') return reply(405,{error:'Method not allowed'});
  try {
    const jwt=(req.headers.get('authorization') ?? '').replace(/^Bearer\s+/i,'');
    if(!jwt) return reply(401,{error:'Not signed in'});
    const url=Deno.env.get('SUPABASE_URL')!;
    const anon=Deno.env.get('SUPABASE_ANON_KEY')!;
    const admin=createClient(url,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false}});
    const {data:{user},error:userError}=await admin.auth.getUser(jwt);
    if(userError || !user?.email) return reply(401,{error:'Invalid session'});
    if(!user.identities?.some(i=>['google','facebook'].includes(i.provider))) return reply(403,{error:'Social sign-in required'});
    const {code}=await req.json();
    if(typeof code !== 'string' || !/^\d{6}$/.test(code)) return reply(400,{error:'Enter a six-digit code'});
    const {data:state,error:rpcError}=await admin.rpc('kaisa_otp_consume_attempt',{p_user:user.id});
    if(rpcError) {console.error('Attempt counter error',rpcError);return reply(500,{error:'Could not check attempt limit'});}
    if(state.error) return reply(200,state);
    const verifier=createClient(url,anon,{auth:{persistSession:false}});
    const {data:result,error:otpError}=await verifier.auth.verifyOtp({email:user.email,token:code,type:'email'});
    if(otpError || result.user?.id !== user.id) {
      return reply(200,{error:state.attempts >= 5 ? 'Invalid code. 5 attempts used; request a new code.' : 'Invalid code',attempts:state.attempts,resends:state.resends,expires_at:state.expires_at});
    }
    const {error:saveError}=await admin.from('social_otp_verifications').upsert({user_id:user.id,verified_at:new Date().toISOString()},{onConflict:'user_id'});
    if(saveError) {console.error('OTP proof write failed',saveError);return reply(500,{error:'Could not save verification'});}
    return reply(200,{verified:true});
  } catch(e) {console.error('confirm-social-otp',e);return reply(500,{error:'OTP verification unavailable'});}
});
