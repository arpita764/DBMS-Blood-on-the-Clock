"use client";

import { useEffect, useState } from "react";
import { apiFetch } from "@/lib/api-client";
import { Shell } from "@/components/Shell";
import { Card, Button, Input, Select, Badge, Th, Td, EmptyState, Modal } from "@/components/ui";
import { statusColor, formatDateShort } from "@/lib/format";

interface Donor {
  donor_id: number;
  donor_name: string;
  phone: string;
  city: string;
  group_name: string;
  hospital_name: string;
  availability_status: string;
  last_donation_date: string | null;
}
interface Hosp { hospital_id: number; hospital_name: string; city: string }
interface Group { blood_group_id: number; group_name: string }

export default function DonorsPage() {
  const [donors, setDonors] = useState<Donor[]>([]);
  const [hospitals, setHospitals] = useState<Hosp[]>([]);
  const [groups, setGroups] = useState<Group[]>([]);
  const [available, setAvailable] = useState("");
  const [group, setGroup] = useState("");
  const [err, setErr] = useState("");
  const [msg, setMsg] = useState("");
  const [showNew, setShowNew] = useState(false);

  const [nName, setNName] = useState("");
  const [nPhone, setNPhone] = useState("");
  const [nCity, setNCity] = useState("");
  const [nGroup, setNGroup] = useState("");
  const [nHosp, setNHosp] = useState("");

  async function load() {
    setErr("");
    try {
      const [d, h, g] = await Promise.all([
        apiFetch<Donor[]>("/api/donors"),
        apiFetch<Hosp[]>("/api/hospitals"),
        apiFetch<Group[]>("/api/blood/groups"),
      ]);
      setDonors(d);
      setHospitals(h);
      setGroups(g);
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
      const out = await apiFetch<{ message: string }>("/api/donors", {
        method: "POST",
        body: JSON.stringify({ donor_name: nName, phone: nPhone, city: nCity, blood_group_id: nGroup, hospital_id: nHosp }),
      });
      flash(out.message);
      setShowNew(false);
      setNName(""); setNPhone(""); setNCity(""); setNGroup(""); setNHosp("");
      load();
    } catch (e) {
      flash(e instanceof Error ? e.message : "Failed");
    }
  }

  const filtered = donors.filter(
    (d) => (!available || d.availability_status === available) && (!group || d.group_name === group)
  );

  return (
    <Shell>
      <div className="mb-4 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-800">Donor Registry</h1>
        <Button onClick={() => setShowNew(true)}>+ Register Donor</Button>
      </div>
      {err && <div className="mb-3 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">{err}</div>}
      {msg && <div className="mb-3 rounded-lg bg-green-50 px-3 py-2 text-sm text-green-700">{msg}</div>}
      <Card>
        <div className="mb-4 flex flex-wrap gap-3">
          <Select label="Availability" value={available} onChange={(e) => setAvailable(e.target.value)} className="w-48">
            <option value="">All</option>
            <option value="AVAILABLE">Available</option>
            <option value="UNAVAILABLE">Unavailable</option>
          </Select>
          <Select label="Blood group" value={group} onChange={(e) => setGroup(e.target.value)} className="w-40">
            <option value="">All groups</option>
            {groups.map((g) => <option key={g.blood_group_id} value={g.group_name}>{g.group_name}</option>)}
          </Select>
        </div>
        {filtered.length === 0 ? (
          <EmptyState message="No donors match the filters" />
        ) : (
          <table className="w-full">
            <thead>
              <tr>
                <Th>Name</Th><Th>Phone</Th><Th>City</Th><Th>Group</Th>
                <Th>Registered at</Th><Th>Status</Th><Th>Last donation</Th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((d) => (
                <tr key={d.donor_id} className="border-b border-gray-50">
                  <Td className="font-medium">{d.donor_name}</Td>
                  <Td>{d.phone}</Td>
                  <Td>{d.city}</Td>
                  <Td><Badge className="bg-gray-100">{d.group_name}</Badge></Td>
                  <Td>{d.hospital_name}</Td>
                  <Td><Badge className={statusColor(d.availability_status)}>{d.availability_status}</Badge></Td>
                  <Td>{formatDateShort(d.last_donation_date)}</Td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>

      <Modal open={showNew} onClose={() => setShowNew(false)} title="Register donor">
        <div className="space-y-3">
          <Input label="Donor name" value={nName} onChange={(e) => setNName(e.target.value)} />
          <div className="grid grid-cols-2 gap-3">
            <Input label="Phone" value={nPhone} onChange={(e) => setNPhone(e.target.value)} />
            <Input label="City" value={nCity} onChange={(e) => setNCity(e.target.value)} />
          </div>
          <Select label="Blood group" value={nGroup} onChange={(e) => setNGroup(e.target.value)}>
            <option value="">Select group…</option>
            {groups.map((g) => <option key={g.blood_group_id} value={g.blood_group_id}>{g.group_name}</option>)}
          </Select>
          <Select label="Registering hospital" value={nHosp} onChange={(e) => setNHosp(e.target.value)}>
            <option value="">Select hospital…</option>
            {hospitals.map((h) => <option key={h.hospital_id} value={h.hospital_id}>{h.hospital_name}</option>)}
          </Select>
          <Button className="w-full" onClick={create}>Register</Button>
        </div>
      </Modal>
    </Shell>
  );
}
