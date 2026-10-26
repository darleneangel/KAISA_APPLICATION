import { createClient } from 'npm:@supabase/supabase-js@2';
const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const reply = (status: number, data: Record<string, unknown>) =>
  new Response(JSON.stringify(data), {status, headers: {...cors, 'Content-Type':'application/json'}});
Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') return new Response(null, {headers:cors});
  if (req.method !== 'POST') return reply(405, {error:'Method not allowed'});
  try {
    const jwt = (req.headers.get('authorization') ?? '').replace(/^Bearer\s+/i,'');
    if (!jwt) return reply(401,{error:'Not signed in'});
    const url = Deno.env.get('SUPABASE_URL')!;
    const anon = Deno.env.get('SUPABASE_ANON_KEY')!;
    const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {auth:{persistSession:false}});
    const {data:{user}, error:authError} = await admin.auth.getUser(jwt);
    if (authError || !user?.email) return reply(401,{error:'Invalid session'});
    if (!user.identities?.some(i=>['google','facebook'].includes(i.provider)))
      return reply(403,{error:'Social sign-in required'});
    const {action='send'} = await req.json();
    if (!['send','resend','status'].includes(action)) return reply(400,{error:'Unknown action'});
    const {data:completed, error:completionError} = await admin.from('social_otp_verifications')
      .select('user_id').eq('user_id',user.id).maybeSingle();
    if (completionError) return reply(500,{error:'Cannot read verification status'});
    if (completed) return reply(200,{verified:true});
    if (action === 'status') {
      const {data, error} = await admin.from('social_otp_challenges').select('expires_at,attempts,resend_count').eq('user_id',user.id).maybeSingle();
      if (error) return reply(500,{error:'Cannot read challenge status'});
      return reply(200,{expires_at:data?.expires_at ?? null, attempts:data?.attempts ?? 0,resends:data?.resend_count ?? 0, sent:false});
    }
    const {data:state,error:issueError} = await admin.rpc('kaisa_otp_issue',{p_user:user.id,p_resend:action==='resend'});
    if (issueError) {console.error('OTP state error',issueError);return reply(500,{error:'Cannot prepare OTP request'});}
    if (state.error) return reply(200,state);
    if (!state.send) return reply(200,{...state,sent:false});
    const client = createClient(url,anon,{auth:{persistSession:false}});
    const {error:sendError} = await client.auth.signInWithOtp({email:user.email,options:{shouldCreateUser:false}});
    if (sendError) {
      console.error('Email send error',sendError.message);
      // State stays reserved for anti-abuse; retry after cooldown. Do not expose internal detail.
      return reply(200,{...state,error:'Could not deliver code. Check SMTP settings or Auth rate limits; retry when timer ends.'});
    }
    return reply(200,{...state,sent:true});
  } catch (e) {console.error('request-social-otp',e);return reply(500,{error:'OTP service unavailable'});}
});
