'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/lib/auth-context';
import { adminAPI } from '@/lib/api';

type User = { id: string; full_name: string; role: string; phone?: string; email?: string; created_at: string; verification_status?: string };

export default function UsersPage() {
    const { token } = useAuth();
    const [users, setUsers] = useState<User[]>([]);
    const [role, setRole] = useState<string | null>(null);
    const [page, setPage] = useState(1);
    const [loading, setLoading] = useState(true);

    useEffect(() => { if (token) loadUsers(); }, [token, role, page]);

    const loadUsers = async () => {
        setLoading(true);
        try {
            const res = await adminAPI.users(role, page, token!) as { items: User[] };
            setUsers(res.items || []);
        } catch (e) { console.error(e); }
        setLoading(false);
    };

    const roles = ['All', 'patient', 'doctor', 'clinic_admin', 'lab_admin', 'pharmacy_admin', 'super_admin'];
    const roleColors: Record<string, string> = {
        patient: 'bg-blue-50 text-blue-600', doctor: 'bg-green-50 text-green-600',
        clinic_admin: 'bg-purple-50 text-purple-600', lab_admin: 'bg-yellow-50 text-yellow-600',
        pharmacy_admin: 'bg-teal-50 text-teal-600', super_admin: 'bg-red-50 text-red-600',
    };

    return (
        <div>
            <h1 className="text-2xl font-bold mb-6">User Management</h1>
            <div className="flex gap-2 mb-6 flex-wrap">
                {roles.map((r) => (
                    <button key={r} onClick={() => { setRole(r === 'All' ? null : r); setPage(1); }}
                        className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${(role === r || (r === 'All' && !role)) ? 'bg-[#0f3460] text-white' : 'bg-white text-[#6b7280] border border-[#e5e7eb]'}`}>
                        {r.replace('_', ' ').replace(/\b\w/g, c => c.toUpperCase())}
                    </button>
                ))}
            </div>

            {loading ? (
                <div className="flex justify-center py-12"><div className="animate-spin h-8 w-8 border-4 border-[#0f3460] border-t-transparent rounded-full" /></div>
            ) : (
                <div className="bg-white rounded-2xl border border-[#e5e7eb] overflow-hidden">
                    <table className="w-full text-sm">
                        <thead className="bg-gray-50">
                            <tr>
                                <th className="px-5 py-3 text-left font-semibold">Name</th>
                                <th className="px-5 py-3 text-left font-semibold">Role</th>
                                <th className="px-5 py-3 text-left font-semibold">Contact</th>
                                <th className="px-5 py-3 text-left font-semibold">Joined</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-[#e5e7eb]">
                            {users.map((u) => (
                                <tr key={u.id} className="hover:bg-gray-50 transition-colors">
                                    <td className="px-5 py-3 font-medium">{u.full_name}</td>
                                    <td className="px-5 py-3">
                                        <span className={`px-2 py-1 rounded-lg text-xs font-medium ${roleColors[u.role] || 'bg-gray-50'}`}>
                                            {u.role.replace('_', ' ')}
                                        </span>
                                    </td>
                                    <td className="px-5 py-3 text-[#6b7280]">{u.phone || u.email || '-'}</td>
                                    <td className="px-5 py-3 text-[#6b7280]">{u.created_at?.substring(0, 10) || '-'}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                    <div className="flex justify-between items-center p-4 border-t border-[#e5e7eb]">
                        <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}
                            className="px-3 py-1.5 text-sm text-[#6b7280] hover:text-[#0f3460] disabled:opacity-30">← Previous</button>
                        <span className="text-sm text-[#6b7280]">Page {page}</span>
                        <button onClick={() => setPage(p => p + 1)} disabled={users.length < 20}
                            className="px-3 py-1.5 text-sm text-[#6b7280] hover:text-[#0f3460] disabled:opacity-30">Next →</button>
                    </div>
                </div>
            )}
        </div>
    );
}
