import { AlertCircle, CheckCircle, Info, X, XCircle } from 'lucide-react';
import React from 'react';
import { useToast } from '../../contexts/ToastContext';

const Toast: React.FC = () => {
  const { toasts, removeToast } = useToast();

  if (toasts.length === 0) return null;

  const getIcon = (type: string) => {
    switch (type) {
      case 'success':
        return <CheckCircle className="h-5 w-5 text-green-400" />;
      case 'error':
        return <XCircle className="h-5 w-5 text-red-400" />;
      case 'warning':
        return <AlertCircle className="h-5 w-5 text-yellow-400" />;
      case 'info':
        return <Info className="h-5 w-5 text-blue-400" />;
      default:
        return <Info className="h-5 w-5 text-blue-400" />;
    }
  };

  const getStyles = (type: string) => {
    switch (type) {
      case 'success':
        return 'glass border-green-500/50 shadow-glow';
      case 'error':
        return 'glass border-red-500/50 shadow-glow';
      case 'warning':
        return 'glass border-yellow-500/50 shadow-glow';
      case 'info':
        return 'glass border-blue-500/50 shadow-glow';
      default:
        return 'glass border-blue-500/50 shadow-glow';
    }
  };

  return (
    <div className="fixed top-4 right-4 z-50 space-y-3 safe-area-inset">
      {toasts.map(toast => (
        <div
          key={toast.id}
          className={`max-w-sm w-full rounded-xl ${getStyles(toast.type)} animate-slide-down`}
        >
          <div className="content-padding">
            <div className="flex items-start space-x-3">
              <div className="flex-shrink-0 mt-1">
                {getIcon(toast.type)}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-white leading-relaxed">
                  {toast.message}
                </p>
              </div>
              <div className="flex-shrink-0">
                <button
                  onClick={() => removeToast(toast.id)}
                  className="btn-ghost p-1 rounded-lg hover:bg-white/20 transition-all duration-200"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default Toast;