'use client';
import { AuthProvider } from '@/lib/auth-context';
import Sidebar from '@/components/layout/Sidebar';
export default function Layout({ children }: { children: React.ReactNode }) {
    return <AuthProvider><div className="flex min-h-screen"><Sidebar /><main className="flex-1 overflow-auto"><div className="p-8">{children}</div></main></div></AuthProvider>;
}
