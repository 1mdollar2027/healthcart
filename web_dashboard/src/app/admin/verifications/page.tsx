'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/lib/auth-context';
import { adminAPI } from '@/lib/api';

type Entity = { id: string;[key: string]: unknown };

export default function VerificationsPage() {
    const { token } = useAuth();
    const [tab, setTab] = useState<'doctors' | 'labs' | 'pharmacies'>('doctors');
    const [items, setItems] = useState<Entity[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => { if (token) loadData(); }, [token, tab]);

    const loadData = async () => {
        setLoading(true);
        try {
            const res = await adminAPI.pendingVerifications(tab, token!) as { items: Entity[] };
            setItems(res.items || []);
        } catch (e) { console.error(e); }
        setLoading(false);
    };

    const handleAction = async (id: string, action: 'verified' | 'rejected') => {
        if (!token) return;
        try {
            await adminAPI.verify(tab, id, action, token);
            loadData();
        } catch (e) { console.error(e); }
    };

    return (
        <div>
            <h1 className="text-2xl font-bold mb-6">KYC Verifications</h1>
            <div className="flex gap-2 mb-6">
                {(['doctors', 'labs', 'pharmacies'] as const).map((t) => (
                    <button key={t} onClick={() => setTab(t)}
                        className={`px-4 py-2 rounded-xl text-sm font-medium transition-all ${tab === t ? 'bg-[#0f3460] text-white' : 'bg-white text-[#6b7280] border border-[#e5e7eb] hover:bg-gray-50'}`}>
                        {t.charAt(0).toUpperCase() + t.slice(1)}
                    </button>
                ))}
            </div>

            {loading ? (
                <div className="flex justify-center py-12"><div className="animate-spin h-8 w-8 border-4 border-[#0f3460] border-t-transparent rounded-full" /></div>
            ) : items.length === 0 ? (
                <div className="text-center py-12 text-[#6b7280]">
                    <p className="text-4xl mb-3">✅</p>
                    <p className="font-medium">No pending verifications</p>
                </div>
            ) : (
                <div className="space-y-4">
                    {items.map((item) => (
                        <div key={item.id} className="bg-white rounded-2xl p-5 border border-[#e5e7eb]">
                            <div className="flex items-center justify-between">
                                <div>
                                    <h3 className="font-semibold">{(item as Record<string, string>).name || (item as Record<string, string>).full_name || 'Unknown'}</h3>
                                    <p className="text-sm text-[#6b7280]">
                                        {tab === 'doctors' && `Reg: ${(item as Record<string, string>).registration_number || ''} • ${(item as Record<string, string>).specialization || ''}`}
                                        {tab === 'labs' && `${(item as Record<string, string>).address_line || ''}`}
                                        {tab === 'pharmacies' && `License: ${(item as Record<string, string>).license_number || ''}`}
                                    </p>
                                </div>
                                <div className="flex gap-2">
                                    <button onClick={() => handleAction(item.id, 'rejected')}
                                        className="px-4 py-2 bg-red-50 text-red-600 text-sm font-medium rounded-xl hover:bg-red-100 transition-colors">
                                        Reject
                                    </button>
                                    <button onClick={() => handleAction(item.id, 'verified')}
                                        className="px-4 py-2 bg-green-50 text-green-600 text-sm font-medium rounded-xl hover:bg-green-100 transition-colors">
                                        Verify ✓
                                    </button>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}
