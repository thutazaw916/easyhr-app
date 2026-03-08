import axios from 'axios';
import Cookies from 'js-cookie';

const api = axios.create({
  baseURL: '/api',
  headers: { 'Content-Type': 'application/json' },
});

// Add auth token to requests
api.interceptors.request.use((config) => {
  const token = Cookies.get('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Handle 401
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401 && typeof window !== 'undefined') {
      Cookies.remove('token');
      window.location.href = '/login';
    }
    return Promise.reject(err);
  }
);

// Auth
export const login = (email: string, password: string) => api.post('/auth/admin/login', { email, password });
export const getMe = () => api.get('/employees/me');
export const companySignUp = (data: any) => api.post('/auth/company/signup', data);
export const verifyCompany = (email: string, verification_code: string) => api.post('/auth/company/verify', { email, verification_code });
export const setPassword = (data: any) => api.post('/auth/company/set-password', data);

// Dashboard
export const getDashboardStats = () => api.get('/employees?limit=1');

// Employees
export const getEmployees = (params?: Record<string, string>) => api.get('/employees', { params });
export const getEmployee = (id: string) => api.get(`/employees/${id}`);
export const addEmployee = (data: any) => api.post('/employees', data);
export const updateEmployee = (id: string, data: any) => api.put(`/employees/${id}`, data);
export const deleteEmployee = (id: string) => api.delete(`/employees/${id}`);

// Attendance
export const getAttendanceReport = (params?: Record<string, string>) => api.get('/attendance/report', { params });
export const getDailyReport = (date?: string) => api.get('/attendance/daily', { params: { date } });

// Leave
export const getLeaveTypes = () => api.get('/leave/types');
export const getPendingLeaves = () => api.get('/leave/pending');
export const approveLeave = (id: string) => api.put(`/leave/${id}/approve`);
export const rejectLeave = (id: string, reason: string) => api.put(`/leave/${id}/reject`, { rejection_reason: reason });

// Payroll
export const getMonthlyPayroll = (year: number, month: number) => api.get('/payroll/monthly', { params: { year, month } });
export const calculatePayroll = (year: number, month: number) => api.post('/payroll/calculate', null, { params: { year, month } });
export const getSalaryStructures = () => api.get('/payroll/salary-structures');

// Departments & Branches
export const getDepartments = () => api.get('/departments');
export const addDepartment = (data: any) => api.post('/departments', data);
export const getBranches = () => api.get('/branches');
export const addBranch = (data: any) => api.post('/branches', data);

// Company
export const getCompanySettings = () => api.get('/company/settings');
export const updateCompanySettings = (data: any) => api.put('/company/settings', data);

// Billing
export const getPlans = () => api.get('/billing/plans');
export const getSubscription = () => api.get('/billing/subscription');
export const getPaymentHistory = () => api.get('/billing/payments');
export const getPendingPayments = () => api.get('/billing/admin/pending');
export const approvePayment = (id: string) => api.put(`/billing/admin/approve/${id}`);
export const rejectPayment = (id: string, reason: string) => api.put(`/billing/admin/reject/${id}`, { reason });

// Announcements
export const getAnnouncements = () => api.get('/announcements');
export const createAnnouncement = (data: any) => api.post('/announcements', data);

export default api;
