import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "HealthCart Dashboard",
  description: "HealthCart Telemedicine Platform – Admin Dashboard",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet" />
      </head>
      <body className="font-[Inter] bg-[#f8faff] text-[#1a1a2e] antialiased">
        {children}
      </body>
    </html>
  );
}
