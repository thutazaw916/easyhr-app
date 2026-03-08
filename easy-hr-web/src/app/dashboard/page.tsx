'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { getEmployees, getPendingLeaves, getAnnouncements, getSubscription } from '@/lib/api';
import { Users, UserCheck, CalendarDays, CreditCard, TrendingUp, Clock, AlertCircle } from 'lucide-react';

export default function DashboardPage() {
  const { user } = useAuth();
  const [stats, setStats] = useState<any>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      const [empRes, leaveRes, annRes, subRes] = await Promise.allSettled([
        getEmployees({ limit: '1' }),
        getPendingLeaves(),
        getAnnouncements(),
        getSubscription(),
      ]);

      setStats({
        totalEmployees: empRes.status === 'fulfilled' ? empRes.value.data.pagination?.total || 0 : 0,
        pendingLeaves: leaveRes.status === 'fulfilled' ? (leaveRes.value.data?.length || 0) : 0,
        announcements: annRes.status === 'fulfilled' ? (annRes.value.data?.length || 0) : 0,
        subscription: subRes.status === 'fulfilled' ? subRes.value.data : null,
      });
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const cards = [
    { label: 'Total Employees', value: stats.totalEmployees || 0, icon: Users, color: 'bg-blue-500', bg: 'bg-blue-50' },
    { label: 'Pending Leaves', value: stats.pendingLeaves || 0, icon: CalendarDays, color: 'bg-amber-500', bg: 'bg-amber-50' },
    { label: 'Plan', value: stats.subscription?.current_plan?.label || 'Free', icon: CreditCard, color: 'bg-emerald-500', bg: 'bg-emerald-50' },
    { label: 'Days Remaining', value: stats.subscription?.days_remaining || 0, icon: Clock, color: 'bg-purple-500', bg: 'bg-purple-50' },
  ];

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">
          Welcome back, {user?.first_name}! 👋
        </h1>
        <p className="text-gray-500 mt-1">Here&apos;s what&apos;s happening with your company today.</p>
      </div>

      {loading ? (
        <div className="flex justify-center py-20">
          <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
        </div>
      ) : (
        <>
          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            {cards.map((card, i) => (
              <div key={i} className="bg-white rounded-2xl p-6 border border-gray-100 shadow-sm hover:shadow-md transition">
                <div className="flex items-center justify-between mb-4">
                  <div className={`w-12 h-12 ${card.bg} rounded-xl flex items-center justify-center`}>
                    <card.icon className={`w-6 h-6 text-${card.color.replace('bg-', '')}`} style={{ color: card.color === 'bg-blue-500' ? '#3b82f6' : card.color === 'bg-amber-500' ? '#f59e0b' : card.color === 'bg-emerald-500' ? '#10b981' : '#a855f7' }} />
                  </div>
                  <TrendingUp className="w-4 h-4 text-green-500" />
                </div>
                <p className="text-3xl font-bold text-gray-900">{card.value}</p>
                <p className="text-sm text-gray-500 mt-1">{card.label}</p>
              </div>
            ))}
          </div>

          {/* Quick Actions */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="bg-white rounded-2xl p-6 border border-gray-100">
              <h3 className="text-lg font-semibold mb-4">Quick Actions</h3>
              <div className="grid grid-cols-2 gap-3">
                <a href="/dashboard/employees" className="p-4 rounded-xl bg-blue-50 hover:bg-blue-100 transition text-center">
                  <Users className="w-6 h-6 text-blue-500 mx-auto mb-2" />
                  <span className="text-sm font-medium text-gray-700">Manage Employees</span>
                </a>
                <a href="/dashboard/leave" className="p-4 rounded-xl bg-amber-50 hover:bg-amber-100 transition text-center">
                  <CalendarDays className="w-6 h-6 text-amber-500 mx-auto mb-2" />
                  <span className="text-sm font-medium text-gray-700">Leave Requests</span>
                </a>
                <a href="/dashboard/payroll" className="p-4 rounded-xl bg-emerald-50 hover:bg-emerald-100 transition text-center">
                  <CreditCard className="w-6 h-6 text-emerald-500 mx-auto mb-2" />
                  <span className="text-sm font-medium text-gray-700">Payroll</span>
                </a>
                <a href="/dashboard/settings" className="p-4 rounded-xl bg-purple-50 hover:bg-purple-100 transition text-center">
                  <AlertCircle className="w-6 h-6 text-purple-500 mx-auto mb-2" />
                  <span className="text-sm font-medium text-gray-700">Settings</span>
                </a>
              </div>
            </div>

            <div className="bg-white rounded-2xl p-6 border border-gray-100">
              <h3 className="text-lg font-semibold mb-4">Subscription</h3>
              {stats.subscription ? (
                <div>
                  <div className="flex items-center justify-between mb-3">
                    <span className="text-gray-500">Current Plan</span>
                    <span className="font-bold text-primary text-lg">{stats.subscription.current_plan?.label || 'Free'}</span>
                  </div>
                  <div className="flex items-center justify-between mb-3">
                    <span className="text-gray-500">Employees</span>
                    <span className="font-semibold">{stats.subscription.employee_count} / {stats.subscription.max_employees}</span>
                  </div>
                  <div className="flex items-center justify-between mb-3">
                    <span className="text-gray-500">Days Left</span>
                    <span className="font-semibold">{stats.subscription.days_remaining}</span>
                  </div>
                  <div className="w-full bg-gray-100 rounded-full h-2 mt-4">
                    <div
                      className="bg-primary rounded-full h-2 transition-all"
                      style={{ width: `${Math.min(100, ((stats.subscription.employee_count || 0) / (stats.subscription.max_employees || 1)) * 100)}%` }}
                    />
                  </div>
                  <p className="text-xs text-gray-400 mt-2">Employee usage</p>
                </div>
              ) : (
                <p className="text-gray-400">Loading...</p>
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
