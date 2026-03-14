'use client';
export default function ClinicDashboard() {
    return (
        <div>
            <h1 className="text-2xl font-bold mb-2">Clinic Dashboard</h1>
            <p className="text-[#6b7280] mb-8">Manage your clinic, doctors, and appointments</p>
            <div className="grid grid-cols-3 gap-5 mb-8">
                <div className="bg-white rounded-2xl p-5 border border-[#e5e7eb]"><p className="text-3xl font-bold text-[#0f3460]">0</p><p className="text-sm text-[#6b7280]">Doctors</p></div>
                <div className="bg-white rounded-2xl p-5 border border-[#e5e7eb]"><p className="text-3xl font-bold text-green-600">0</p><p className="text-sm text-[#6b7280]">Appointments Today</p></div>
                <div className="bg-white rounded-2xl p-5 border border-[#e5e7eb]"><p className="text-3xl font-bold text-[#e94560]">₹0</p><p className="text-sm text-[#6b7280]">Revenue</p></div>
            </div>
        </div>
    );
}
