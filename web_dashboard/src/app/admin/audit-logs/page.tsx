'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/lib/auth-context';
import { adminAPI } from '@/lib/api';

type AuditLog = { id: string; action: string; resource_type: string; resource_id: string; details?: Record<string, unknown>; created_at: string; profiles?: { full_name: string } };

export default function AuditLogsPage() {
    const { token } = useAuth();
    const [logs, setLogs] = useState<AuditLog[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (!token) return;
        adminAPI.auditLogs(token)
            .then((res) => setLogs((res as { items: AuditLog[] }).items || []))
            .catch(console.error)
            .finally(() => setLoading(false));
    }, [token]);

    return (
        <div>
            <h1 className="text-2xl font-bold mb-6">Audit Logs</h1>
            {loading ? (
                <div className="flex justify-center py-12"><div className="animate-spin h-8 w-8 border-4 border-[#0f3460] border-t-transparent rounded-full" /></div>
            ) : logs.length === 0 ? (
                <div className="text-center py-12 text-[#6b7280]"><p>No audit logs yet</p></div>
            ) : (
                <div className="bg-white rounded-2xl border border-[#e5e7eb] overflow-hidden">
                    <table className="w-full text-sm">
                        <thead className="bg-gray-50">
                            <tr>
                                <th className="px-5 py-3 text-left font-semibold">Time</th>
                                <th className="px-5 py-3 text-left font-semibold">User</th>
                                <th className="px-5 py-3 text-left font-semibold">Action</th>
                                <th className="px-5 py-3 text-left font-semibold">Resource</th>
                                <th className="px-5 py-3 text-left font-semibold">Details</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-[#e5e7eb]">
                            {logs.map((log) => (
                                <tr key={log.id} className="hover:bg-gray-50">
                                    <td className="px-5 py-3 text-[#6b7280] text-xs">{log.created_at?.substring(0, 19).replace('T', ' ')}</td>
                                    <td className="px-5 py-3 font-medium">{log.profiles?.full_name || '-'}</td>
                                    <td className="px-5 py-3">
                                        <span className="px-2 py-1 bg-blue-50 text-blue-600 rounded text-xs font-medium">{log.action}</span>
                                    </td>
                                    <td className="px-5 py-3 text-[#6b7280]">{log.resource_type} / {log.resource_id?.substring(0, 8)}</td>
                                    <td className="px-5 py-3 text-xs text-[#6b7280]">{log.details ? JSON.stringify(log.details) : '-'}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    );
}
