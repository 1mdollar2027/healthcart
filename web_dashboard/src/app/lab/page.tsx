'use client';
export default function LabDashboard() {
    return (
        <div>
            <h1 className="text-2xl font-bold mb-2">Lab Dashboard</h1>
            <p className="text-[#6b7280] mb-8">Manage bookings, results, and technicians</p>
            <div className="grid grid-cols-3 gap-5 mb-8">
                <div className="bg-white rounded-2xl p-5 border border-[#e5e7eb]"><p className="text-3xl font-bold text-yellow-600">0</p><p className="text-sm text-[#6b7280]">New Bookings</p></div>
                <div className="bg-white rounded-2xl p-5 border border-[#e5e7eb]"><p className="text-3xl font-bold text-[#0f3460]">0</p><p className="text-sm text-[#6b7280]">In Progress</p></div>
                <div className="bg-white rounded-2xl p-5 border border-[#e5e7eb]"><p className="text-3xl font-bold text-green-600">0</p><p className="text-sm text-[#6b7280]">Completed Today</p></div>
            </div>
        </div>
    );
}
