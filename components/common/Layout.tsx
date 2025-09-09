import { Code2, Database, LogOut, Menu, Monitor, Server, User, X } from 'lucide-react';
import React, { useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import EnhancedNotificationBell from '../features/EnhancedNotificationBell';

interface LayoutProps {
  children: React.ReactNode;
  title: string;
}

const Layout: React.FC<LayoutProps> = ({ children, title }) => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const { user, logout } = useAuth();

  const handleLogout = () => {
    logout();
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-primary-900 to-secondary-900 relative overflow-hidden">
      {/* Enhanced animated background elements */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-primary-500/20 rounded-full mix-blend-multiply filter blur-xl animate-pulse"></div>
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-secondary-500/20 rounded-full mix-blend-multiply filter blur-xl animate-pulse animate-bounce-subtle"></div>
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-60 h-60 bg-primary-400/15 rounded-full mix-blend-multiply filter blur-xl animate-pulse"></div>
        
        {/* Additional ambient particles */}
        <div className="absolute top-1/4 right-1/4 w-32 h-32 bg-secondary-400/10 rounded-full filter blur-2xl animate-float"></div>
        <div className="absolute bottom-1/4 left-1/4 w-24 h-24 bg-primary-300/10 rounded-full filter blur-2xl animate-float-delay-1"></div>
      </div>

      {/* Floating tech icons - Enhanced with better positioning */}
      <div className="absolute inset-0 pointer-events-none hidden lg:block">
        <Code2 className="absolute top-20 left-20 w-4 h-4 text-primary-400/30 animate-float" />
        <Server className="absolute top-40 right-32 w-5 h-5 text-secondary-400/25 animate-float-delay-1" />
        <Database className="absolute bottom-32 left-32 w-4 h-4 text-primary-300/30 animate-float-delay-2" />
        <Monitor className="absolute bottom-20 right-20 w-4 h-4 text-secondary-300/30 animate-float" />
        <Code2 className="absolute top-1/3 right-1/3 w-3 h-3 text-primary-200/20 animate-float-delay-1" />
        <Database className="absolute bottom-1/3 right-1/4 w-3 h-3 text-secondary-200/20 animate-float-delay-2" />
      </div>

      {/* Mobile sidebar backdrop with enhanced blur */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black/60 lg:hidden z-40 backdrop-blur-sm"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Enhanced Header with better glass morphism */}
      <header className="glass sticky top-0 z-30 shadow-large border-b border-white/10">
        <div className="section-padding py-0">
          <div className="flex justify-between h-16 items-center">
            {/* Left section with mobile menu and branding */}
            <div className="flex items-center space-x-4">
              <button
                type="button"
                className="lg:hidden btn-ghost p-2 rounded-xl"
                onClick={() => setSidebarOpen(!sidebarOpen)}
              >
                {sidebarOpen ? (
                  <X className="h-6 w-6" />
                ) : (
                  <Menu className="h-6 w-6" />
                )}
              </button>
              
              <div className="flex items-center space-x-3">
                <div className="h-10 w-10 bg-gradient-to-br from-primary-500 to-secondary-600 rounded-xl flex items-center justify-center shadow-glow">
                  <span className="text-white font-bold text-lg">E</span>
                </div>
                <div className="hidden sm:block">
                  <h1 className="text-xl font-bold text-white">
                    {title}
                  </h1>
                  <p className="text-xs text-white/60 font-medium">EduConnect Platform</p>
                </div>
                <h1 className="sm:hidden text-lg font-bold text-white">
                  {title}
                </h1>
              </div>
            </div>

            {/* Right section with notifications and user menu */}
            <div className="flex items-center space-x-3 sm:space-x-4">
              <EnhancedNotificationBell />
              
              {/* Enhanced user profile section */}
              <div className="flex items-center space-x-3">
                <div className="glass-soft rounded-2xl px-3 py-2 border border-white/20">
                  <div className="flex items-center space-x-3">
                    <div className="h-8 w-8 bg-gradient-to-br from-primary-500 to-secondary-600 rounded-xl flex items-center justify-center shadow-soft">
                      <User className="h-4 w-4 text-white" />
                    </div>
                    <div className="hidden lg:block">
                      <div className="text-sm font-semibold text-white">{user?.name}</div>
                      <div className="text-xs text-white/70 capitalize font-medium">{user?.role?.toLowerCase()}</div>
                    </div>
                  </div>
                </div>
                
                <button
                  onClick={handleLogout}
                  className="btn-ghost p-2 rounded-xl hover:bg-red-500/20 hover:text-red-200 group"
                  title="Logout"
                >
                  <LogOut className="h-5 w-5 group-hover:scale-110 transition-all duration-300" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Enhanced Main content with better spacing */}
      <main className="flex-1 relative z-10">
        <div className="max-w-7xl mx-auto section-padding">
          <div className="animate-fade-in">
            {children}
          </div>
        </div>
      </main>
      
      {/* Footer for better professional feel */}
      <footer className="relative z-10 mt-auto">
        <div className="glass-soft border-t border-white/10">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
            <div className="flex flex-col sm:flex-row justify-between items-center text-white/60 text-sm">
              <div className="flex items-center space-x-2 mb-2 sm:mb-0">
                <div className="h-5 w-5 bg-gradient-to-br from-primary-500 to-secondary-600 rounded flex items-center justify-center">
                  <span className="text-white font-bold text-xs">E</span>
                </div>
                <span className="font-medium">© 2024 EduConnect Platform</span>
              </div>
              <div className="flex items-center space-x-4 text-xs">
                <span>Version 2.0</span>
                <span className="hidden sm:inline">|</span>
                <span className="hidden sm:inline">Powered by AI Technology</span>
              </div>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Layout;