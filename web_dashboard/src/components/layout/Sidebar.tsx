'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/lib/auth-context';

const navItems: Record<string, { label: string; icon: string; href: string }[]> = {
    super_admin: [
        { label: 'Dashboard', icon: '📊', href: '/admin' },
        { label: 'Verifications', icon: '✅', href: '/admin/verifications' },
        { label: 'Users', icon: '👥', href: '/admin/users' },
        { label: 'Audit Logs', icon: '📝', href: '/admin/audit-logs' },
    ],
    doctor: [
        { label: 'Dashboard', icon: '🏠', href: '/doctor' },
        { label: 'Appointments', icon: '📅', href: '/doctor/appointments' },
    ],
    clinic_admin: [
        { label: 'Dashboard', icon: '🏥', href: '/clinic' },
        { label: 'Appointments', icon: '📅', href: '/clinic/appointments' },
        { label: 'Revenue', icon: '💰', href: '/clinic/revenue' },
    ],
    lab_admin: [
        { label: 'Dashboard', icon: '🔬', href: '/lab' },
        { label: 'Bookings', icon: '📋', href: '/lab/bookings' },
    ],
    pharmacy_admin: [
        { label: 'Dashboard', icon: '💊', href: '/pharmacy' },
        { label: 'Orders', icon: '📦', href: '/pharmacy/orders' },
    ],
};

export default function Sidebar() {
    const pathname = usePathname();
    const { profile, signOut } = useAuth();
    const role = profile?.role || 'super_admin';
    const items = navItems[role] || navItems.super_admin;

    return (
        <aside className="w-64 min-h-screen bg-[#0f3460] text-white flex flex-col">
            {/* Logo */}
            <div className="p-6 border-b border-white/10">
                <h1 className="text-xl font-bold">
                    Health<span className="text-[#e94560]">Cart</span>
                </h1>
                <p className="text-xs text-white/60 mt-1">
                    {role.replace('_', ' ').replace(/\b\w/g, c => c.toUpperCase())} Panel
                </p>
            </div>

            {/* Nav */}
            <nav className="flex-1 p-4 space-y-1">
                {items.map((item) => {
                    const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
                    return (
                        <Link key={item.href} href={item.href}
                            className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all
                ${isActive ? 'bg-white/15 text-white' : 'text-white/70 hover:bg-white/8 hover:text-white'}`}>
                            <span className="text-lg">{item.icon}</span>
                            {item.label}
                        </Link>
                    );
                })}
            </nav>

            {/* User info */}
            <div className="p-4 border-t border-white/10">
                <div className="flex items-center gap-3 mb-3">
                    <div className="w-9 h-9 rounded-full bg-white/20 flex items-center justify-center text-sm font-bold">
                        {profile?.full_name?.[0] || 'A'}
                    </div>
                    <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium truncate">{profile?.full_name || 'Admin'}</p>
                        <p className="text-xs text-white/50 truncate">{profile?.email || ''}</p>
                    </div>
                </div>
                <button onClick={signOut}
                    className="w-full py-2 text-sm text-white/60 hover:text-white hover:bg-white/10 rounded-lg transition-all">
                    ← Sign Out
                </button>
            </div>
        </aside>
    );
}
