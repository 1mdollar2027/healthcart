const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1';

type FetchOptions = {
  method?: string;
  body?: unknown;
  token?: string;
};

async function apiFetch<T = unknown>(path: string, options: FetchOptions = {}): Promise<T> {
  const { method = 'GET', body, token } = options;
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
    cache: 'no-store',
  });

  if (!res.ok) {
    const error = await res.json().catch(() => ({ detail: 'Request failed' }));
    throw new Error(error.detail || `HTTP ${res.status}`);
  }

  return res.json();
}

// ── Admin ──
export const adminAPI = {
  dashboard: (token: string) => apiFetch('/admin/dashboard', { token }),
  pendingVerifications: (type: string, token: string) =>
    apiFetch(`/admin/pending-verifications?entity_type=${type}`, { token }),
  verify: (type: string, id: string, action: string, token: string) =>
    apiFetch(`/admin/verify/${type}/${id}?action=${action}`, { method: 'POST', token }),
  users: (role: string | null, page: number, token: string) =>
    apiFetch(`/admin/users?page=${page}${role ? `&role=${role}` : ''}`, { token }),
  auditLogs: (token: string) => apiFetch('/admin/audit-logs', { token }),
};

// ── Doctor ──
export const doctorAPI = {
  appointments: (status: string, token: string) =>
    apiFetch(`/bookings/appointments?status=${status}`, { token }),
  updateAppointment: (id: string, data: unknown, token: string) =>
    apiFetch(`/bookings/appointments/${id}`, { method: 'PATCH', body: data, token }),
};

// ── Clinic ──
export const clinicAPI = {
  myClinics: (token: string) => apiFetch('/clinics/my-clinics', { token }),
  appointments: (clinicId: string, token: string) =>
    apiFetch(`/clinics/${clinicId}/appointments`, { token }),
  revenue: (clinicId: string, token: string) =>
    apiFetch(`/clinics/${clinicId}/revenue`, { token }),
};

// ── Lab ──
export const labAPI = {
  bookings: (token: string) => apiFetch('/labs/bookings', { token }),
  updateBooking: (id: string, data: unknown, token: string) =>
    apiFetch(`/labs/bookings/${id}`, { method: 'PATCH', body: data, token }),
};

// ── Pharmacy ──
export const pharmacyAPI = {
  orders: (token: string) => apiFetch('/pharmacies/orders', { token }),
  updateOrder: (id: string, data: unknown, token: string) =>
    apiFetch(`/pharmacies/orders/${id}`, { method: 'PATCH', body: data, token }),
};

// ── Auth ──
export const authAPI = {
  profile: (token: string) => apiFetch('/auth/profile', { token }),
};
