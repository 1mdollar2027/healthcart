'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL || '',
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
);

export default function LoginPage() {
    const [email, setEmail] = useState('admin@healthcart.in');
    const [password, setPassword] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const router = useRouter();

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            const { error } = await supabase.auth.signInWithPassword({ email, password });
            if (error) throw error;

            // Get profile to determine role
            const { data: { user } } = await supabase.auth.getUser();
            if (user) {
                const { data: profile } = await supabase.from('profiles').select('role').eq('id', user.id).single();
                const role = profile?.role || 'super_admin';
                const routes: Record<string, string> = {
                    super_admin: '/admin',
                    doctor: '/doctor',
                    clinic_admin: '/clinic',
                    lab_admin: '/lab',
                    pharmacy_admin: '/pharmacy',
                };
                router.push(routes[role] || '/admin');
            }
        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : 'Login failed');
        }
        setLoading(false);
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-[#0f3460] to-[#16213e]">
            <div className="w-full max-w-md">
                <div className="bg-white rounded-2xl shadow-2xl p-8">
                    {/* Logo */}
                    <div className="text-center mb-8">
                        <div className="inline-flex items-center gap-3 mb-3">
                            <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-[#0f3460] to-[#1a5276] flex items-center justify-center">
                                <span className="text-white text-2xl">❤️</span>
                            </div>
                            <h1 className="text-2xl font-bold">
                                <span className="text-[#0f3460]">Health</span>
                                <span className="text-[#e94560]">Cart</span>
                            </h1>
                        </div>
                        <p className="text-[#6b7280] text-sm">Admin Dashboard Login</p>
                    </div>

                    {error && (
                        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-xl text-red-600 text-sm">{error}</div>
                    )}

                    <form onSubmit={handleLogin} className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium mb-1.5">Email</label>
                            <input type="email" value={email} onChange={(e) => setEmail(e.target.value)}
                                className="w-full px-4 py-3 border border-[#e5e7eb] rounded-xl focus:outline-none focus:ring-2 focus:ring-[#0f3460] focus:border-transparent"
                                placeholder="admin@healthcart.in" required />
                        </div>
                        <div>
                            <label className="block text-sm font-medium mb-1.5">Password</label>
                            <input type="password" value={password} onChange={(e) => setPassword(e.target.value)}
                                className="w-full px-4 py-3 border border-[#e5e7eb] rounded-xl focus:outline-none focus:ring-2 focus:ring-[#0f3460] focus:border-transparent"
                                placeholder="••••••••" required />
                        </div>
                        <button type="submit" disabled={loading}
                            className="w-full py-3.5 bg-[#0f3460] text-white font-semibold rounded-xl hover:bg-[#1a5276] transition-colors disabled:opacity-50">
                            {loading ? 'Signing in...' : 'Sign In'}
                        </button>
                    </form>

                    <p className="mt-6 text-center text-xs text-[#6b7280]">
                        Test: admin@healthcart.in / Admin@2026!
                    </p>
                </div>
            </div>
        </div>
    );
}
