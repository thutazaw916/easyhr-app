'use client';
import { useEffect, useState, useRef } from 'react';
import { getBranches, toggleBranchQr } from '@/lib/api';
import { QrCode, Download, Power, PowerOff, Building2, MapPin, RefreshCw } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
import { useToast } from '@/components/ui/toast';
import { useConfirm } from '@/components/ui/confirm-dialog';

export default function QrCodePage() {
  const [branches, setBranches] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [toggling, setToggling] = useState<string | null>(null);
  const { toast } = useToast();
  const { confirm } = useConfirm();

  useEffect(() => { loadBranches(); }, []);

  const loadBranches = async () => {
    setLoading(true);
    try {
      const res = await getBranches();
      setBranches(res.data || []);
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  const handleToggleQr = async (branch: any) => {
    const enabling = !branch.qr_code_enabled;
    const ok = await confirm({
      title: enabling ? 'Enable QR Code' : 'Disable QR Code',
      message: enabling
        ? `Enable QR code attendance for "${branch.name}"? Employees can scan this code to check in.`
        : `Disable QR code for "${branch.name}"? The current QR code will be invalidated.`,
      confirmText: enabling ? 'Enable' : 'Disable',
      variant: enabling ? 'info' : 'warning',
    });
    if (!ok) return;

    setToggling(branch.id);
    try {
      await toggleBranchQr(branch.id, enabling);
      toast(enabling ? 'QR Code enabled!' : 'QR Code disabled', 'success');
      loadBranches();
    } catch (e: any) {
      toast(e.response?.data?.message || 'Failed to toggle QR code', 'error');
    }
    setToggling(null);
  };

  const downloadQr = (branch: any) => {
    const svgEl = document.getElementById(`qr-${branch.id}`);
    if (!svgEl) return;

    const svgData = new XMLSerializer().serializeToString(svgEl);
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    const img = new Image();

    img.onload = () => {
      canvas.width = 1024;
      canvas.height = 1200;
      if (!ctx) return;

      // Background
      ctx.fillStyle = '#1C1C1E';
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      // White QR area with rounded rect
      const qrPadding = 60;
      const qrSize = canvas.width - qrPadding * 2;
      ctx.fillStyle = '#FFFFFF';
      roundRect(ctx, qrPadding, qrPadding, qrSize, qrSize, 24);
      ctx.fill();

      // QR Code
      const qrImgPadding = 100;
      ctx.drawImage(img, qrImgPadding, qrImgPadding, canvas.width - qrImgPadding * 2, canvas.width - qrImgPadding * 2);

      // Branch name text
      ctx.fillStyle = '#FFFFFF';
      ctx.font = 'bold 36px Inter, system-ui, sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText(branch.name, canvas.width / 2, canvas.width - qrPadding + 70);

      // Subtitle
      ctx.fillStyle = '#8E8E93';
      ctx.font = '24px Inter, system-ui, sans-serif';
      ctx.fillText('Scan to Check In • Easy HR', canvas.width / 2, canvas.width - qrPadding + 110);

      // Download
      const link = document.createElement('a');
      link.download = `EasyHR-QR-${branch.name.replace(/\s+/g, '-')}.png`;
      link.href = canvas.toDataURL('image/png');
      link.click();
    };

    img.src = 'data:image/svg+xml;base64,' + btoa(unescape(encodeURIComponent(svgData)));
  };

  function roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.lineTo(x + w - r, y);
    ctx.quadraticCurveTo(x + w, y, x + w, y + r);
    ctx.lineTo(x + w, y + h - r);
    ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
    ctx.lineTo(x + r, y + h);
    ctx.quadraticCurveTo(x, y + h, x, y + h - r);
    ctx.lineTo(x, y + r);
    ctx.quadraticCurveTo(x, y, x + r, y);
    ctx.closePath();
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-white">QR Code Attendance</h1>
          <p className="text-[#8E8E93] text-sm mt-1">Generate QR codes for employee check-in at each branch</p>
        </div>
        <button onClick={loadBranches} className="flex items-center gap-2 px-4 py-2.5 bg-[#1C1C1E] border border-[#38383A] text-[#8E8E93] rounded-xl hover:bg-[#2C2C2E] hover:text-white transition text-sm font-medium">
          <RefreshCw size={16} /> Refresh
        </button>
      </div>

      {loading ? (
        <div className="flex justify-center py-20">
          <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
        </div>
      ) : branches.length === 0 ? (
        <div className="bg-[#1C1C1E] rounded-2xl border border-[#38383A] p-20 text-center">
          <Building2 className="w-12 h-12 mx-auto mb-3 text-[#8E8E93] opacity-30" />
          <p className="text-[#8E8E93] font-medium">No branches found</p>
          <p className="text-[#8E8E93] text-sm mt-1">Add a branch in Settings first, then enable QR code here</p>
          <a href="/dashboard/settings" className="inline-block mt-4 px-4 py-2 bg-primary text-white rounded-xl text-sm font-medium">
            Go to Settings
          </a>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {branches.map((branch) => (
            <div key={branch.id} className="bg-[#1C1C1E] rounded-2xl border border-[#38383A] overflow-hidden">
              {/* Branch Header */}
              <div className="p-5 border-b border-[#2C2C2E] flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-primary/15 flex items-center justify-center">
                    <Building2 size={20} className="text-primary" />
                  </div>
                  <div>
                    <h3 className="font-semibold text-white">{branch.name}</h3>
                    {branch.address && (
                      <p className="text-xs text-[#8E8E93] flex items-center gap-1 mt-0.5">
                        <MapPin size={10} /> {branch.address}
                      </p>
                    )}
                  </div>
                </div>
                <button
                  onClick={() => handleToggleQr(branch)}
                  disabled={toggling === branch.id}
                  className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium transition disabled:opacity-50 ${
                    branch.qr_code_enabled
                      ? 'bg-red-500/15 text-red-400 hover:bg-red-500/25'
                      : 'bg-emerald-500/15 text-emerald-400 hover:bg-emerald-500/25'
                  }`}
                >
                  {toggling === branch.id ? (
                    <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin" />
                  ) : branch.qr_code_enabled ? (
                    <><PowerOff size={16} /> Disable</>
                  ) : (
                    <><Power size={16} /> Enable</>
                  )}
                </button>
              </div>

              {/* QR Code Display */}
              <div className="p-6">
                {branch.qr_code_enabled && branch.qr_secret_key ? (
                  <div className="flex flex-col items-center">
                    <div className="bg-white p-6 rounded-2xl mb-4">
                      <QRCodeSVG
                        id={`qr-${branch.id}`}
                        value={branch.qr_secret_key}
                        size={200}
                        level="H"
                        includeMargin={false}
                      />
                    </div>
                    <p className="text-xs text-[#8E8E93] mb-4 text-center">
                      Employees scan this QR code with the Easy HR app to check in
                    </p>
                    <button
                      onClick={() => downloadQr(branch)}
                      className="flex items-center gap-2 px-5 py-2.5 bg-primary text-white rounded-xl hover:bg-primary-700 transition font-medium text-sm shadow-sm shadow-primary/20"
                    >
                      <Download size={16} /> Download QR Code
                    </button>
                  </div>
                ) : (
                  <div className="text-center py-8">
                    <QrCode className="w-16 h-16 mx-auto mb-3 text-[#8E8E93] opacity-20" />
                    <p className="text-[#8E8E93] text-sm">QR code is disabled for this branch</p>
                    <p className="text-[#8E8E93] text-xs mt-1">Enable it to generate a QR code for employee check-in</p>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Info Section */}
      <div className="mt-8 bg-[#1C1C1E] rounded-2xl border border-[#38383A] p-6">
        <h3 className="text-white font-semibold mb-3 flex items-center gap-2">
          <QrCode size={18} className="text-primary" /> How QR Code Attendance Works
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {[
            { step: '1', title: 'Enable & Download', desc: 'Enable QR code for your branch and download the image' },
            { step: '2', title: 'Print & Display', desc: 'Print the QR code and place it at your office entrance' },
            { step: '3', title: 'Scan to Check In', desc: 'Employees open the Easy HR app and scan to check in/out' },
          ].map((item) => (
            <div key={item.step} className="flex gap-3">
              <div className="w-8 h-8 rounded-lg bg-primary/15 flex items-center justify-center text-primary font-bold text-sm shrink-0">
                {item.step}
              </div>
              <div>
                <p className="text-white text-sm font-medium">{item.title}</p>
                <p className="text-[#8E8E93] text-xs mt-0.5">{item.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
