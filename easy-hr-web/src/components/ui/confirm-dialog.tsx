'use client';
import { createContext, useContext, useState, useCallback, ReactNode } from 'react';
import { AlertTriangle, Trash2, X } from 'lucide-react';

interface ConfirmOptions {
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  variant?: 'danger' | 'warning' | 'info';
}

interface ConfirmContextType {
  confirm: (options: ConfirmOptions) => Promise<boolean>;
  prompt: (title: string, message: string, placeholder?: string) => Promise<string | null>;
}

const ConfirmContext = createContext<ConfirmContextType>({
  confirm: () => Promise.resolve(false),
  prompt: () => Promise.resolve(null),
});

export const useConfirm = () => useContext(ConfirmContext);

const variantStyles = {
  danger: { icon: Trash2, iconBg: 'bg-red-50', iconColor: 'text-red-500', btnBg: 'bg-red-500 hover:bg-red-600' },
  warning: { icon: AlertTriangle, iconBg: 'bg-amber-50', iconColor: 'text-amber-500', btnBg: 'bg-amber-500 hover:bg-amber-600' },
  info: { icon: AlertTriangle, iconBg: 'bg-blue-50', iconColor: 'text-blue-500', btnBg: 'bg-primary hover:bg-primary-700' },
};

export function ConfirmProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<{
    type: 'confirm' | 'prompt';
    options: ConfirmOptions;
    placeholder?: string;
    resolve: (value: any) => void;
  } | null>(null);
  const [promptValue, setPromptValue] = useState('');

  const confirmFn = useCallback((options: ConfirmOptions): Promise<boolean> => {
    return new Promise(resolve => {
      setState({ type: 'confirm', options, resolve });
    });
  }, []);

  const promptFn = useCallback((title: string, message: string, placeholder?: string): Promise<string | null> => {
    return new Promise(resolve => {
      setState({ type: 'prompt', options: { title, message, variant: 'info' }, placeholder, resolve });
      setPromptValue('');
    });
  }, []);

  const handleClose = (value: any) => {
    state?.resolve(value);
    setState(null);
    setPromptValue('');
  };

  const v = variantStyles[state?.options.variant || 'info'];

  return (
    <ConfirmContext.Provider value={{ confirm: confirmFn, prompt: promptFn }}>
      {children}
      {state && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-[90] p-4" onClick={() => handleClose(state.type === 'confirm' ? false : null)}>
          <div className="bg-white rounded-2xl w-full max-w-sm shadow-2xl" onClick={e => e.stopPropagation()}>
            <div className="p-6">
              <div className="flex items-start gap-4">
                <div className={`w-10 h-10 rounded-xl ${v.iconBg} flex items-center justify-center shrink-0`}>
                  <v.icon size={20} className={v.iconColor} />
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="text-lg font-bold text-gray-900">{state.options.title}</h3>
                  <p className="text-sm text-gray-500 mt-1">{state.options.message}</p>
                  {state.type === 'prompt' && (
                    <input
                      autoFocus
                      value={promptValue}
                      onChange={e => setPromptValue(e.target.value)}
                      placeholder={state.placeholder || ''}
                      className="mt-3 w-full px-4 py-2.5 rounded-xl border border-gray-200 outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary text-sm"
                    />
                  )}
                </div>
              </div>
            </div>
            <div className="flex gap-3 px-6 pb-6">
              <button onClick={() => handleClose(state.type === 'confirm' ? false : null)}
                className="flex-1 py-2.5 rounded-xl border border-gray-200 text-gray-600 hover:bg-gray-50 font-medium text-sm transition">
                {state.options.cancelText || 'Cancel'}
              </button>
              <button onClick={() => handleClose(state.type === 'confirm' ? true : (promptValue || null))}
                className={`flex-1 py-2.5 rounded-xl text-white font-medium text-sm transition ${v.btnBg}`}>
                {state.options.confirmText || 'Confirm'}
              </button>
            </div>
          </div>
        </div>
      )}
    </ConfirmContext.Provider>
  );
}
