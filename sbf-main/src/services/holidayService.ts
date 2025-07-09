import api from './api';

export interface Holiday {
  _id: string;
  name: string;
  date: string;
  reason: string;
  type: 'fixed' | 'dynamic' | 'store';
  category: 'national' | 'religious' | 'store' | 'maintenance' | 'other';
  isActive: boolean;
  year: number;
  month: number;
  day: number;
  recurring: boolean;
  recurringYears: number[];
  createdBy: {
    _id: string;
    name: string;
    email: string;
  };
  createdAt: string;
  updatedAt: string;
}

export interface CreateHolidayData {
  name: string;
  date: string;
  reason: string;
  type?: 'fixed' | 'dynamic' | 'store';
  category?: 'national' | 'religious' | 'store' | 'maintenance' | 'other';
  isActive?: boolean;
  recurring?: boolean;
  recurringYears?: number[];
}

export interface UpdateHolidayData extends Partial<CreateHolidayData> {}

export interface HolidayStats {
  year: number;
  total: number;
  active: number;
  inactive: number;
  categoryStats: Array<{ _id: string; count: number }>;
  typeStats: Array<{ _id: string; count: number }>;
}

class HolidayService {
  // Get all holidays (admin only)
  async getAllHolidays(params?: {
    year?: number;
    category?: string;
    type?: string;
    isActive?: boolean;
  }): Promise<{ success: boolean; data: Holiday[]; count: number }> {
    const response = await api.get('/holidays', { params });
    return response.data;
  }

  // Get holidays for a specific year (public)
  async getHolidaysForYear(year: number): Promise<{ success: boolean; data: Holiday[]; year: number; count: number }> {
    const response = await api.get(`/holidays/year/${year}`);
    return response.data;
  }

  // Get holidays for a date range (public)
  async getHolidaysForDateRange(startDate: string, endDate: string): Promise<{
    success: boolean;
    data: Holiday[];
    startDate: string;
    endDate: string;
    count: number;
  }> {
    const response = await api.get('/holidays/range', {
      params: { startDate, endDate }
    });
    return response.data;
  }

  // Check if a specific date is a holiday (public)
  async checkHoliday(date: string): Promise<{
    success: boolean;
    isHoliday: boolean;
    holiday: Holiday | null;
  }> {
    const response = await api.get(`/holidays/check/${date}`);
    return response.data;
  }

  // Create a new holiday (admin only)
  async createHoliday(holidayData: CreateHolidayData): Promise<{
    success: boolean;
    message: string;
    data: Holiday;
  }> {
    const response = await api.post('/holidays', holidayData);
    return response.data;
  }

  // Update a holiday (admin only)
  async updateHoliday(id: string, holidayData: UpdateHolidayData): Promise<{
    success: boolean;
    message: string;
    data: Holiday;
  }> {
    const response = await api.put(`/holidays/${id}`, holidayData);
    return response.data;
  }

  // Delete a holiday (admin only)
  async deleteHoliday(id: string): Promise<{
    success: boolean;
    message: string;
    data: Holiday;
  }> {
    const response = await api.delete(`/holidays/${id}`);
    return response.data;
  }

  // Toggle holiday active status (admin only)
  async toggleHolidayStatus(id: string): Promise<{
    success: boolean;
    message: string;
    data: Holiday;
  }> {
    const response = await api.patch(`/holidays/${id}/toggle`);
    return response.data;
  }

  // Get holiday statistics (admin only)
  async getHolidayStats(year?: number): Promise<{
    success: boolean;
    data: HolidayStats;
  }> {
    const response = await api.get('/holidays/stats', {
      params: year ? { year } : undefined
    });
    return response.data;
  }

  // Helper method to get holidays for current year
  async getCurrentYearHolidays(): Promise<Holiday[]> {
    const currentYear = new Date().getFullYear();
    const response = await this.getHolidaysForYear(currentYear);
    return response.data;
  }

  // Helper method to check if a date is disabled for delivery
  async isDateDisabledForDelivery(date: Date): Promise<{
    isDisabled: boolean;
    reason?: string;
    holiday?: Holiday;
  }> {
    const dateString = date.toISOString().split('T')[0];
    const response = await this.checkHoliday(dateString);
    
    if (response.isHoliday && response.holiday) {
      return {
        isDisabled: true,
        reason: response.holiday.reason,
        holiday: response.holiday
      };
    }
    
    return {
      isDisabled: false
    };
  }

  // Helper method to get all disabled dates for a year
  async getDisabledDatesForYear(year: number): Promise<Date[]> {
    const holidays = await this.getHolidaysForYear(year);
    return holidays.data
      .filter(holiday => holiday.isActive)
      .map(holiday => new Date(holiday.date));
  }

  // Helper method to format holiday for display
  formatHolidayForDisplay(holiday: Holiday): {
    name: string;
    date: string;
    reason: string;
    category: string;
    type: string;
    status: string;
  } {
    return {
      name: holiday.name,
      date: new Date(holiday.date).toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      }),
      reason: holiday.reason,
      category: holiday.category.charAt(0).toUpperCase() + holiday.category.slice(1),
      type: holiday.type.charAt(0).toUpperCase() + holiday.type.slice(1),
      status: holiday.isActive ? 'Active' : 'Inactive'
    };
  }
}

export default new HolidayService(); 