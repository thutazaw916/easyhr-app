import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter;
  private fromEmail: string;

  constructor(private configService: ConfigService) {
    this.fromEmail = this.configService.get('GMAIL_USER') || '';
    this.transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: this.fromEmail,
        pass: this.configService.get('GMAIL_APP_PASSWORD') || '',
      },
    });
  }

  async sendVerificationCode(to: string, companyName: string, code: string): Promise<boolean> {
    try {
      await this.transporter.sendMail({
        from: `Easy HR <${this.fromEmail}>`,
        to,
        subject: `Easy HR - Verification Code: ${code}`,
        html: `
          <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 480px; margin: 0 auto; padding: 40px 20px;">
            <div style="text-align: center; margin-bottom: 30px;">
              <div style="display: inline-block; background: #4F46E5; color: white; font-weight: bold; font-size: 20px; width: 50px; height: 50px; line-height: 50px; border-radius: 12px;">HR</div>
              <h1 style="margin: 15px 0 5px; font-size: 24px; color: #111827;">Easy HR</h1>
              <p style="color: #6b7280; margin: 0;">Myanmar SME HR Platform</p>
            </div>
            <div style="background: #f9fafb; border-radius: 16px; padding: 30px; text-align: center; border: 1px solid #e5e7eb;">
              <p style="color: #374151; margin: 0 0 5px;">Welcome, <strong>${companyName}</strong>!</p>
              <p style="color: #6b7280; margin: 0 0 20px; font-size: 14px;">Your verification code is:</p>
              <div style="background: white; border: 2px solid #4F46E5; border-radius: 12px; padding: 15px; display: inline-block;">
                <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #4F46E5;">${code}</span>
              </div>
              <p style="color: #9ca3af; font-size: 13px; margin: 20px 0 0;">This code will expire in 30 minutes.</p>
            </div>
            <p style="color: #9ca3af; font-size: 12px; text-align: center; margin-top: 30px;">
              If you didn't request this, please ignore this email.<br/>
              &copy; 2026 Easy HR - Myanmar
            </p>
          </div>
        `,
      });

      this.logger.log(`Verification email sent to ${to}`);
      return true;
    } catch (err) {
      this.logger.error(`Email send error: ${err}`);
      return false;
    }
  }
}
