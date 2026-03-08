export default function PrivacyPage() {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4">
      <div className="max-w-3xl mx-auto bg-white rounded-2xl shadow-sm border border-gray-100 p-8 md:p-12">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center text-white font-bold text-sm">HR</div>
          <h1 className="text-3xl font-bold text-gray-900">Privacy Policy</h1>
        </div>
        <p className="text-sm text-gray-400 mb-8">Last updated: March 8, 2026</p>

        <div className="prose prose-gray max-w-none space-y-6">
          <section>
            <h2 className="text-xl font-bold text-gray-900 mb-3">1. Introduction</h2>
            <p className="text-gray-600 leading-relaxed">
              Easy HR (&quot;we&quot;, &quot;our&quot;, or &quot;us&quot;) is committed to protecting the privacy of our users. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application and web dashboard.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-gray-900 mb-3">2. Information We Collect</h2>
            <ul className="list-disc pl-6 text-gray-600 space-y-2">
              <li><strong>Personal Information:</strong> Name, phone number, NRC number, gender, employee code, position, and join date provided during employee registration.</li>
              <li><strong>Location Data:</strong> GPS coordinates collected during attendance check-in/check-out to verify work location. Location is only accessed when you actively check in or out.</li>
              <li><strong>Attendance Data:</strong> Check-in/check-out times, work hours, and attendance status.</li>
              <li><strong>Camera Access:</strong> Used for QR code scanning for attendance purposes only.</li>
              <li><strong>Device Information:</strong> Device type and operating system for app functionality.</li>
            </ul>
          </section>

          <section>
            <h2 className="text-xl font-bold text-gray-900 mb-3">3. How We Use Your Information</h2>
            <ul className="list-disc pl-6 text-gray-600 space-y-2">
              <li>To manage employee attendance and work hours</li>
              <li>To process payroll calculations</li>
              <li>To manage leave requests and approvals</li>
              <li>To send work-related notifications and announcements</li>
              <li>To verify check-in location for attendance accuracy</li>
              <li>To generate HR reports for company administrators</li>
            </ul>
          </section>

          <section>
            <h2 className="text-xl font-bold text-gray-900 mb-3">4. Data Storage & Security</h2>
            <p className="text-gray-600 leading-relaxed">
              Your data is stored securely on cloud servers with encryption. We use industry-standard security measures including JWT authentication, encrypted connections (HTTPS), and secure database storage. We do not sell, trade, or transfer your personal information to third parties.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-gray-900 mb-3">5. Data Sharing</h2>
            <p className="text-gray-600 leading-relaxed">
              Your personal data is only accessible to authorized administrators within your company. We do not share your data with external third parties except as required by Myanmar law.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-gray-900 mb-3">6. Your Rights</h2>
            <ul className="list-disc pl-6 text-gray-600 space-y-2">
              <li>Access your personal data stored in the system</li>
              <li>Request correction of inaccurate information</li>
              <li>Request deletion of your account and data</li>
              <li>Opt out of non-essential notifications</li>
            </ul>
          </section>

          <section>
            <h2 className="text-xl font-bold text-gray-900 mb-3">7. Permissions Used</h2>
            <ul className="list-disc pl-6 text-gray-600 space-y-2">
              <li><strong>Location:</strong> Required for GPS-based attendance check-in verification</li>
              <li><strong>Camera:</strong> Required for QR code scanning attendance</li>
              <li><strong>Notifications:</strong> For work reminders, leave approvals, and announcements</li>
            </ul>
          </section>

          <section>
            <h2 className="text-xl font-bold text-gray-900 mb-3">8. Children&apos;s Privacy</h2>
            <p className="text-gray-600 leading-relaxed">
              Our service is intended for use by adults in a professional work environment. We do not knowingly collect information from children under 18.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-gray-900 mb-3">9. Changes to This Policy</h2>
            <p className="text-gray-600 leading-relaxed">
              We may update this Privacy Policy from time to time. We will notify users of any material changes through the app or email.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-gray-900 mb-3">10. Contact Us</h2>
            <p className="text-gray-600 leading-relaxed">
              If you have questions about this Privacy Policy, please contact us at:
            </p>
            <div className="mt-3 p-4 bg-gray-50 rounded-xl">
              <p className="text-gray-700 font-medium">Easy HR Myanmar</p>
              <p className="text-gray-500 text-sm">Website: https://easyhr-mm.com</p>
            </div>
          </section>
        </div>
      </div>
    </div>
  );
}
