'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/lib/auth-context';
import { adminAPI } from '@/lib/api';

type DashboardData = {
    total_patients: number;
    total_doctors: number;
    total_clinics: number;
    total_labs: number;
    total_pharmacies: number;
    total_appointments: number;
    total_revenue: number;
    pending_verifications: {
        doctors: number;
        labs: number;
        pharmacies: number;
    };
};

export default function AdminDashboard() {
    const { token } = useAuth();
    const [data, setData] = useState<DashboardData | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (!token) return;
        adminAPI.dashboard(token)
            .then((d) => setData(d as DashboardData))
            .catch(console.error)
            .finally(() => setLoading(false));
    }, [token]);

    if (loading) return <div className="flex items-center justify-center h-64"><div className="animate-spin h-8 w-8 border-4 border-[#0f3460] border-t-transparent rounded-full" /></div>;

    const stats = [
        { label: 'Total Patients', value: data?.total_patients || 0, icon: '👥', color: 'bg-blue-50 text-blue-600' },
        { label: 'Total Doctors', value: data?.total_doctors || 0, icon: '🩺', color: 'bg-green-50 text-green-600' },
        { label: 'Total Clinics', value: data?.total_clinics || 0, icon: '🏥', color: 'bg-purple-50 text-purple-600' },
        { label: 'Total Labs', value: data?.total_labs || 0, icon: '🔬', color: 'bg-yellow-50 text-yellow-600' },
        { label: 'Total Pharmacies', value: data?.total_pharmacies || 0, icon: '💊', color: 'bg-teal-50 text-teal-600' },
        { label: 'Appointments', value: data?.total_appointments || 0, icon: '📅', color: 'bg-pink-50 text-pink-600' },
        { label: 'Total Revenue', value: `₹${(data?.total_revenue || 0).toLocaleString()}`, icon: '💰', color: 'bg-emerald-50 text-emerald-600' },
    ];

    const pendingTotal = (data?.pending_verifications?.doctors || 0) +
        (data?.pending_verifications?.labs || 0) + (data?.pending_verifications?.pharmacies || 0);

    return (
        <div>
            <div className="flex items-center justify-between mb-8">
                <div>
                    <h1 className="text-2xl font-bold">Super Admin Dashboard</h1>
                    <p className="text-[#6b7280] text-sm mt-1">HealthCart Platform Overview</p>
                </div>
                {pendingTotal > 0 && (
                    <a href="/admin/verifications"
                        className="px-4 py-2 bg-[#e94560] text-white text-sm font-medium rounded-xl hover:bg-[#d13350] transition-colors">
                        ⚠️ {pendingTotal} Pending Verifications
                    </a>
                )}
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5 mb-8">
                {stats.map((s) => (
                    <div key={s.label} className="bg-white rounded-2xl p-5 border border-[#e5e7eb] hover:shadow-md transition-shadow">
                        <div className="flex items-center gap-3 mb-3">
                            <div className={`w-10 h-10 rounded-xl flex items-center justify-center text-lg ${s.color}`}>{s.icon}</div>
                            <p className="text-sm text-[#6b7280] font-medium">{s.label}</p>
                        </div>
                        <p className="text-2xl font-bold">{typeof s.value === 'number' ? s.value.toLocaleString() : s.value}</p>
                    </div>
                ))}
            </div>

            {/* Pending Verifications */}
            <div className="bg-white rounded-2xl p-6 border border-[#e5e7eb]">
                <h2 className="text-lg font-bold mb-4">Pending KYC Verifications</h2>
                <div className="grid grid-cols-3 gap-4">
                    <div className="p-4 bg-blue-50 rounded-xl text-center">
                        <p className="text-3xl font-bold text-blue-600">{data?.pending_verifications?.doctors || 0}</p>
                        <p className="text-sm text-[#6b7280] mt-1">Doctors</p>
                    </div>
                    <div className="p-4 bg-yellow-50 rounded-xl text-center">
                        <p className="text-3xl font-bold text-yellow-600">{data?.pending_verifications?.labs || 0}</p>
                        <p className="text-sm text-[#6b7280] mt-1">Labs</p>
                    </div>
                    <div className="p-4 bg-teal-50 rounded-xl text-center">
                        <p className="text-3xl font-bold text-teal-600">{data?.pending_verifications?.pharmacies || 0}</p>
                        <p className="text-sm text-[#6b7280] mt-1">Pharmacies</p>
                    </div>
                </div>
            </div>
        </div>
    );
}
