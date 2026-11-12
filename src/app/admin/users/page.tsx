"use client";

import { useEffect, useState } from "react";
import { apiFetch } from "@/lib/api-client";
import { Shell } from "@/components/Shell";
import { Card, Button, Input, Select, Badge, Th, Td, EmptyState, Modal } from "@/components/ui";
import { statusColor } from "@/lib/format";

interface User {
  user_id: number;
  full_name: string;
  email: string;
  role: string;
  account_status: string;
  hospital_id: number | null;
  hospital_name: string | null;
}
interface Hosp { hospital_id: number; hospital_name: string; city: string }

export default function AdminUsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [hospitals, setHospitals] = useState<Hosp[]>([]);
  const [err, setErr] = useState("");
  const [msg, setMsg] = useState("");
  const [showNew, setShowNew] = useState(false);

  const [nName, setNName] = useState("");
  const [nEmail, setNEmail] = useState("");
  const [nPass, setNPass] = useState("");
  const [nRole, setNRole] = useState("HOSPITAL_STAFF");
  const [nHosp, setNHosp] = useState("");

  async function load() {
    setErr("");
    try {
      const [u, h] = await Promise.all([
        apiFetch<User[]>("/api/admin/users"),
        apiFetch<Hosp[]>("/api/hospitals"),
      ]);
      setUsers(u);
      setHospitals(h);
    } catch (e) {
      setErr(e instanceof Error ? e.message : "Failed to load");
    }
  }
  useEffect(() => {
    load();
  }, []);

  function flash(m: string) {
    setMsg(m);
    setTimeout(() => setMsg(""), 5000);
  }

  async function create() {
    try {
      const out = await apiFetch<{ message: string }>("/api/admin/users", {
        method: "POST",
        body: JSON.stringify({
          full_name: nName,
          email: nEmail,
          password: nPass,
          role: nRole,
          hospital_id: nHosp || null,
        }),
      });
      flash(out.message);
      setShowNew(false);
      setNName(""); setNEmail(""); setNPass(""); setNHosp("");
      load();
    } catch (e) {
      flash(e instanceof Error ? e.message : "Failed");
    }
  }

  async function toggle(u: User) {
    const next = u.account_status === "ACTIVE" ? "DISABLED" : "ACTIVE";
    try {
      await apiFetch(`/api/admin/users/${u.user_id}`, {
        method: "PATCH",
        body: JSON.stringify({ account_status: next }),
      });
      flash(`User ${next.toLowerCase()}`);
      load();
    } catch (e) {
      flash(e instanceof Error ? e.message : "Failed");
    }
  }

  return (
    <Shell>
      <div className="mb-4 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-800">User Management</h1>
        <Button onClick={() => setShowNew(true)}>+ New User</Button>
      </div>
      {err && <div className="mb-3 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">{err}</div>}
      {msg && <div className="mb-3 rounded-lg bg-green-50 px-3 py-2 text-sm text-green-700">{msg}</div>}

      <Card>
        {users.length === 0 ? (
          <EmptyState message="No users" />
        ) : (
          <table className="w-full">
            <thead>
              <tr>
                <Th>ID</Th><Th>Name</Th><Th>Email</Th><Th>Role</Th>
                <Th>Hospital</Th><Th>Status</Th><Th>Actions</Th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr key={u.user_id} className="border-b border-gray-50">
                  <Td>#{u.user_id}</Td>
                  <Td className="font-medium">{u.full_name}</Td>
                  <Td>{u.email}</Td>
                  <Td>
                    <Badge className={u.role === "ADMIN" ? "bg-purple-100 text-purple-700" : "bg-blue-100 text-blue-700"}>
                      {u.role}
                    </Badge>
                  </Td>
                  <Td>{u.hospital_name || "—"}</Td>
                  <Td><Badge className={statusColor(u.account_status)}>{u.account_status}</Badge></Td>
                  <Td>
                    <Button variant="ghost" onClick={() => toggle(u)}>
                      {u.account_status === "ACTIVE" ? "Disable" : "Enable"}
                    </Button>
                  </Td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>

      <Modal open={showNew} onClose={() => setShowNew(false)} title="Create user">
        <div className="space-y-3">
          <Input label="Full name" value={nName} onChange={(e) => setNName(e.target.value)} />
          <Input label="Email" type="email" value={nEmail} onChange={(e) => setNEmail(e.target.value)} />
          <Input label="Password" type="password" value={nPass} onChange={(e) => setNPass(e.target.value)} />
          <Select label="Role" value={nRole} onChange={(e) => setNRole(e.target.value)}>
            <option value="HOSPITAL_STAFF">HOSPITAL_STAFF</option>
            <option value="ADMIN">ADMIN</option>
          </Select>
          {nRole === "HOSPITAL_STAFF" && (
            <Select label="Hospital" value={nHosp} onChange={(e) => setNHosp(e.target.value)}>
              <option value="">Select hospital…</option>
              {hospitals.map((h) => (
                <option key={h.hospital_id} value={h.hospital_id}>{h.hospital_name} ({h.city})</option>
              ))}
            </Select>
          )}
          <Button className="w-full" onClick={create}>Create user</Button>
          <p className="text-xs text-gray-400">
            Passwords are hashed with bcrypt (cost 12) before storage; never stored in plain text.
          </p>
        </div>
      </Modal>
    </Shell>
  );
}
