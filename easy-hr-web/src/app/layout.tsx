import type { Metadata } from 'next';
import './globals.css';
import { AuthProvider } from '@/lib/auth';

export const metadata: Metadata = {
  title: 'Easy HR - Admin Dashboard',
  description: 'HR Management Dashboard for Myanmar SMEs',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-black min-h-screen text-white">
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
