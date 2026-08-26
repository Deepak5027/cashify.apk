import React, { Component, ErrorInfo, ReactNode } from 'react';
import { AlertTriangle, RefreshCw, Home } from 'lucide-react';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false,
    error: null,
  };

  public static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Uncaught error in UI component tree:', error, errorInfo);
  }

  private handleReload = () => {
    window.location.reload();
  };

  private handleGoHome = () => {
    window.location.href = '/app';
  };

  public render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-[#080c14] text-[#e8edf5] flex items-center justify-center p-6">
          <div
            className="max-w-md w-full p-8 rounded-2xl text-center space-y-6"
            style={{
              background: 'rgba(14,20,35,0.85)',
              border: '1px solid rgba(239,68,68,0.25)',
              boxShadow: '0 8px 32px rgba(0,0,0,0.5)',
            }}
          >
            <div className="w-16 h-16 rounded-2xl bg-red-500/10 border border-red-500/20 flex items-center justify-center mx-auto">
              <AlertTriangle className="w-8 h-8 text-red-400" />
            </div>

            <div className="space-y-2">
              <h2 className="text-2xl font-bold text-white">Something went wrong</h2>
              <p className="text-xs text-gray-400">
                An unexpected UI rendering error occurred. Your financial records are safely stored in the database.
              </p>
            </div>

            {this.state.error && (
              <div className="p-3 bg-red-950/40 border border-red-900/50 rounded-xl text-left font-mono text-xs text-red-300 truncate">
                {this.state.error.message}
              </div>
            )}

            <div className="flex items-center justify-center gap-3 pt-2">
              <button
                onClick={this.handleReload}
                className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white transition-all cursor-pointer"
              >
                <RefreshCw className="w-4 h-4" />
                <span>Reload Page</span>
              </button>
              <button
                onClick={this.handleGoHome}
                className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold bg-blue-600 hover:bg-blue-500 text-white transition-all cursor-pointer shadow-lg shadow-blue-500/20"
              >
                <Home className="w-4 h-4" />
                <span>Return to App</span>
              </button>
            </div>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
