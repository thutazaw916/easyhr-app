import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class ChatbotService {
  private genAI: GoogleGenerativeAI | null = null;
  private model: any = null;

  constructor(
    private configService: ConfigService,
    private supabaseService: SupabaseService,
  ) {
    const apiKey = this.configService.get('GEMINI_API_KEY');
    if (apiKey) {
      this.genAI = new GoogleGenerativeAI(apiKey);
      this.model = this.genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
      console.log('🤖 Gemini AI initialized');
    } else {
      console.warn('⚠️ GEMINI_API_KEY not set - chatbot will use fallback responses');
    }
  }

  private getSystemPrompt(employeeName: string, companyName: string, language: string): string {
    if (language === 'mm') {
      return `သင်သည် "${companyName}" ကုမ္ပဏီ၏ Easy HR AI Assistant ဖြစ်ပါသည်။ 
ဝန်ထမ်း "${employeeName}" ကို ကူညီပေးနေပါသည်။

သင့်တာဝန်များ:
- ခွင့်ယူခြင်း၊ တက်ရောက်မှု၊ လစာ အကြောင်း မေးခွန်းများ ဖြေဆိုပေးခြင်း
- HR မူဝါဒများ ရှင်းပြပေးခြင်း
- ဝန်ထမ်းများ၏ စိတ်ဓာတ်ကို အားပေးခြင်း
- ယဉ်ကျေးမှု၊ ရိုသေမှုဖြင့် ပြန်လည်ဖြေဆိုခြင်း

အဓိက HR အချက်အလက်များ:
- ခွင့်အမျိုးအစား: Casual Leave, Annual Leave, Sick Leave
- တက်ရောက်မှု: QR Code / GPS Check-in/out
- လစာ: လစဉ်လစာ + ခွင့်ပြုငွေ - နုတ်ယူငွေ
- အလုပ်ချိန်: တနင်္လာ-သောကြာ 9:00-17:00 (ပုံမှန်)

မြန်မာဘာသာဖြင့် ဖြေဆိုပါ။ အတိုချုံး၊ ရှင်းလင်းစွာ ဖြေပါ။`;
    }

    return `You are the Easy HR AI Assistant for "${companyName}".
You are helping employee "${employeeName}".

Your responsibilities:
- Answer questions about leave, attendance, payroll, and company policies
- Explain HR processes clearly
- Be friendly, professional, and supportive
- Keep responses concise and helpful

Key HR information:
- Leave types: Casual Leave (6 days/year), Annual Leave (10 days/year), Sick Leave (30 days/year)
- Attendance: QR Code or GPS-based Check-in/Check-out
- Payroll: Monthly salary + allowances - deductions
- Working hours: Monday-Friday 9:00 AM - 5:00 PM (default)
- Overtime: Calculated per hour based on salary structure

Answer in English. Keep responses brief and clear.`;
  }

  async chat(
    message: string,
    employeeId: string,
    companyId: string,
    history: { role: string; content: string }[] = [],
  ) {
    const db = this.supabaseService.getClient();

    // Get employee info
    const { data: employee } = await db
      .from('employees')
      .select('first_name, last_name, language, role')
      .eq('id', employeeId)
      .single();

    // Get company info
    const { data: company } = await db
      .from('companies')
      .select('name')
      .eq('id', companyId)
      .single();

    const empName = employee ? `${employee.first_name} ${employee.last_name || ''}`.trim() : 'Employee';
    const compName = company?.name || 'Company';
    const lang = employee?.language || 'en';

    // Get employee's relevant data for context
    let contextInfo = '';
    try {
      // Leave balances
      const { data: leaveBalances } = await db
        .from('leave_balances')
        .select('leave_type, total_days, used_days, pending_days')
        .eq('employee_id', employeeId);

      if (leaveBalances && leaveBalances.length > 0) {
        contextInfo += '\nEmployee leave balances:\n';
        leaveBalances.forEach(lb => {
          const remaining = lb.total_days - lb.used_days - lb.pending_days;
          contextInfo += `- ${lb.leave_type}: ${remaining} days remaining (used: ${lb.used_days}, pending: ${lb.pending_days})\n`;
        });
      }

      // Today's attendance
      const today = new Date().toISOString().split('T')[0];
      const { data: todayAttendance } = await db
        .from('attendance')
        .select('check_in_time, check_out_time, status')
        .eq('employee_id', employeeId)
        .eq('date', today)
        .single();

      if (todayAttendance) {
        contextInfo += `\nToday's attendance: ${todayAttendance.status}, Check-in: ${todayAttendance.check_in_time || 'N/A'}, Check-out: ${todayAttendance.check_out_time || 'N/A'}\n`;
      } else {
        contextInfo += '\nToday: Not checked in yet\n';
      }
    } catch (e) {
      // Context fetch failed, continue without it
    }

    const systemPrompt = this.getSystemPrompt(empName, compName, lang) + contextInfo;

    // Save user message
    await this._saveMessage(employeeId, companyId, 'user', message);

    let reply: string;

    if (this.model) {
      try {
        // Build chat history for Gemini
        const chatHistory = history.map(h => ({
          role: h.role === 'assistant' ? 'model' : 'user',
          parts: [{ text: h.content }],
        }));

        const chat = this.model.startChat({
          history: [
            { role: 'user', parts: [{ text: systemPrompt }] },
            { role: 'model', parts: [{ text: lang === 'mm' ? 'ဟုတ်ကဲ့၊ ကူညီပေးပါမယ်။' : 'Understood! I\'m ready to help.' }] },
            ...chatHistory,
          ],
        });

        const result = await chat.sendMessage(message);
        reply = result.response.text();
      } catch (e) {
        console.error('Gemini API error:', e);
        reply = this._getFallbackResponse(message, lang);
      }
    } else {
      reply = this._getFallbackResponse(message, lang);
    }

    // Save bot reply
    await this._saveMessage(employeeId, companyId, 'assistant', reply);

    return {
      reply,
      timestamp: new Date().toISOString(),
    };
  }

  async getChatHistory(employeeId: string, limit: number = 50) {
    const db = this.supabaseService.getClient();
    const { data } = await db
      .from('chatbot_messages')
      .select('role, content, created_at')
      .eq('employee_id', employeeId)
      .order('created_at', { ascending: true })
      .limit(limit);

    return data || [];
  }

  async clearHistory(employeeId: string) {
    const db = this.supabaseService.getClient();
    await db
      .from('chatbot_messages')
      .delete()
      .eq('employee_id', employeeId);

    return { message: 'Chat history cleared' };
  }

  private async _saveMessage(employeeId: string, companyId: string, role: string, content: string) {
    const db = this.supabaseService.getClient();
    try {
      await db.from('chatbot_messages').insert({
        employee_id: employeeId,
        company_id: companyId,
        role,
        content,
      });
    } catch (e) {
      console.error('Failed to save chatbot message:', e);
    }
  }

  private _getFallbackResponse(message: string, lang: string): string {
    const msg = message.toLowerCase();

    if (lang === 'mm') {
      if (msg.includes('ခွင့်') || msg.includes('leave')) {
        return 'ခွင့်ယူလိုပါက Leave tab မှတဆင့် request တင်နိုင်ပါတယ်။ Casual Leave (၆ ရက်)၊ Annual Leave (၁၀ ရက်)၊ Sick Leave (၃၀ ရက်) ရှိပါတယ်။';
      }
      if (msg.includes('လစာ') || msg.includes('payroll') || msg.includes('salary')) {
        return 'လစာအချက်အလက်ကို Payroll tab မှာ ကြည့်ရှုနိုင်ပါတယ်။ လစဉ်လစာ = အခြေခံလစာ + ခွင့်ပြုငွေ - နုတ်ယူငွေ။';
      }
      if (msg.includes('တက်ရောက်') || msg.includes('check in') || msg.includes('attendance')) {
        return 'တက်ရောက်မှုမှတ်တမ်းကို Attendance tab မှာ စစ်ဆေးနိုင်ပါတယ်။ QR Code (သို့) GPS ဖြင့် Check-in/out လုပ်နိုင်ပါတယ်။';
      }
      if (msg.includes('ကျေးဇူး') || msg.includes('thank')) {
        return 'ကျေးဇူးတင်ပါတယ်! နောက်ထပ် ကူညီစရာ ရှိရင် မေးပါ။ 😊';
      }
      return 'မင်္ဂလာပါ! ကျွန်တော်/ကျွန်မ Easy HR AI Assistant ဖြစ်ပါတယ်။ ခွင့်၊ တက်ရောက်မှု၊ လစာ အကြောင်း မေးမြန်းနိုင်ပါတယ်။';
    }

    // English fallback
    if (msg.includes('leave')) {
      return 'You can request leave from the Leave tab. Available types: Casual Leave (6 days/year), Annual Leave (10 days/year), Sick Leave (30 days/year).';
    }
    if (msg.includes('salary') || msg.includes('payroll') || msg.includes('pay')) {
      return 'Check your payslip in the Payroll tab. Monthly salary = Basic salary + Allowances - Deductions.';
    }
    if (msg.includes('attendance') || msg.includes('check in') || msg.includes('check out')) {
      return 'View your attendance in the Attendance tab. You can check in/out using QR Code or GPS.';
    }
    if (msg.includes('thank')) {
      return 'You\'re welcome! Let me know if you need anything else. 😊';
    }
    if (msg.includes('hello') || msg.includes('hi') || msg.includes('hey')) {
      return 'Hello! I\'m the Easy HR AI Assistant. I can help you with leave, attendance, payroll, and HR policies. What would you like to know?';
    }
    return 'I\'m the Easy HR AI Assistant. I can help with leave requests, attendance, payroll, and HR policies. What would you like to know?';
  }
}
