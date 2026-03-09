const API = '/api';

function authHeaders(): HeadersInit {
  const token = typeof window !== 'undefined' ? localStorage.getItem('sa_token') : null;
  return {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };
}

async function request(path: string, options?: RequestInit) {
  const res = await fetch(`${API}${path}`, { ...options, headers: { ...authHeaders(), ...options?.headers } });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || `Error ${res.status}`);
  }
  return res.json();
}

// Auth
export const login = (email: string, password: string) =>
  request('/super-admin/login', { method: 'POST', body: JSON.stringify({ email, password }) });

export const setup = (data: { email: string; password: string; name: string }) =>
  request('/super-admin/setup', { method: 'POST', body: JSON.stringify(data) });

// Dashboard
export const getDashboard = () => request('/super-admin/dashboard');
export const getRevenue = () => request('/super-admin/revenue');
export const getAnalytics = (period = '30d') => request(`/super-admin/analytics?period=${period}`);

// Companies
export const getCompanies = (params?: Record<string, string>) => {
  const qs = params ? '?' + new URLSearchParams(params).toString() : '';
  return request(`/super-admin/companies${qs}`);
};
export const getCompanyDetail = (id: string) => request(`/super-admin/companies/${id}`);
export const suspendCompany = (id: string, reason: string) =>
  request(`/super-admin/companies/${id}/suspend`, { method: 'PUT', body: JSON.stringify({ reason }) });
export const unsuspendCompany = (id: string) =>
  request(`/super-admin/companies/${id}/unsuspend`, { method: 'PUT' });
export const updatePlan = (id: string, data: Record<string, unknown>) =>
  request(`/super-admin/companies/${id}/plan`, { method: 'PUT', body: JSON.stringify(data) });

// Payments
export const getPendingPayments = () => request('/billing/admin/pending');
export const getAllPayments = (params?: Record<string, string>) => {
  const qs = params ? '?' + new URLSearchParams(params).toString() : '';
  return request(`/billing/admin/all${qs}`);
};
export const approvePayment = (id: string) =>
  request(`/billing/admin/approve/${id}`, { method: 'PUT' });
export const rejectPayment = (id: string, reason?: string) =>
  request(`/billing/admin/reject/${id}`, { method: 'PUT', body: JSON.stringify({ reason }) });
