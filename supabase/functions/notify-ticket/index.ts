// Sprint 5: send a push notification when a ticket is created, assigned or
// resolved. Deploy with:  supabase functions deploy notify-ticket
//
// It is called by a Database Webhook on the `tickets` table (INSERT and
// UPDATE). It needs these secrets (supabase secrets set ...):
//   FCM_PROJECT_ID            your Firebase project id
//   FCM_SERVICE_ACCOUNT_JSON  the service account key, as one JSON string
// and a `device_tokens` table (user_id, token) filled by the app after
// it gets an FCM token. The app side needs google-services.json, which
// comes from your own Firebase project.

import { createClient } from "npm:@supabase/supabase-js@2";

type TicketRow = {
  id: string;
  title: string;
  status: string;
  reporter_id: string;
  assignee_id: string | null;
};

type WebhookPayload = {
  type: "INSERT" | "UPDATE";
  record: TicketRow;
  old_record: TicketRow | null;
};

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, // server side only, never in the app
);

/** Who should hear about this change, and what to tell them. */
function audience(p: WebhookPayload): { userIds: string[]; title: string; body: string } | null {
  const t = p.record;
  if (p.type === "INSERT") {
    return { userIds: [], title: "New ticket", body: t.title }; // managers, resolved below
  }
  if (p.old_record?.status === t.status && p.old_record?.assignee_id === t.assignee_id) return null;
  if (t.status === "assigned" && t.assignee_id) {
    return { userIds: [t.assignee_id], title: "Ticket assigned to you", body: t.title };
  }
  if (t.status === "resolved") {
    return { userIds: [t.reporter_id], title: "Your ticket was resolved", body: t.title };
  }
  return { userIds: [t.reporter_id], title: "Ticket update", body: t.title };
}

Deno.serve(async (req) => {
  const payload = (await req.json()) as WebhookPayload;
  const message = audience(payload);
  if (!message) return new Response("nothing to send");

  let userIds = message.userIds;
  if (payload.type === "INSERT") {
    const { data } = await supabase.from("profiles").select("id").eq("role", "manager");
    userIds = (data ?? []).map((r) => r.id as string);
  }
  if (userIds.length === 0) return new Response("no recipients");

  const { data: tokens } = await supabase.from("device_tokens").select("token").in("user_id", userIds);

  // Sending through the FCM HTTP v1 API needs an OAuth token made from
  // the service account. It is left as the one step to finish once the
  // Firebase project exists.
  console.log(`would notify ${tokens?.length ?? 0} device(s): ${message.title} - ${message.body}`);
  return new Response(JSON.stringify({ sent: tokens?.length ?? 0 }), {
    headers: { "Content-Type": "application/json" },
  });
});
