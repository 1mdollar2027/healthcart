'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/lib/auth-context';
import { doctorAPI } from '@/lib/api';

type Appointment = { id: string; patient_name?: string; appointment_date: string; appointment_time: string; status: string; reason?: string };

export default function DoctorDashboard() {
    const { token, profile } = useAuth();
    const [appointments, setAppointments] = useState<Appointment[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (!token) return;
        doctorAPI.appointments('confirmed', token)
            .then((res) => setAppointments((res as { items: Appointment[] }).items || []))
            .catch(console.error)
            .finally(() => setLoading(false));
    }, [token]);

    return (
        <div>
            <h1 className="text-2xl font-bold mb-2">Welcome, Dr. {profile?.full_name || 'Doctor'}</h1>
            <p className="text-[#6b7280] mb-8">Your upcoming appointments</p>

            {loading ? (
                <div className="flex justify-center py-12"><div className="animate-spin h-8 w-8 border-4 border-[#0f3460] border-t-transparent rounded-full" /></div>
            ) : appointments.length === 0 ? (
                <div className="text-center py-12 bg-white rounded-2xl border border-[#e5e7eb]">
                    <p className="text-4xl mb-3">📋</p>
                    <p className="text-[#6b7280]">No upcoming appointments</p>
                </div>
            ) : (
                <div className="space-y-3">
                    {appointments.map((a) => (
                        <div key={a.id} className="bg-white rounded-2xl p-5 border border-[#e5e7eb] flex items-center justify-between">
                            <div>
                                <h3 className="font-semibold">{a.patient_name || 'Patient'}</h3>
                                <p className="text-sm text-[#6b7280]">{a.appointment_date} at {a.appointment_time} • {a.reason || 'Consultation'}</p>
                            </div>
                            <div className="flex gap-2">
                                <button className="px-4 py-2 bg-[#0f3460] text-white text-sm font-medium rounded-xl hover:bg-[#1a5276]">Start Call</button>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}
