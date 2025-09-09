import { Briefcase, Code2, Database, Eye, EyeOff, GraduationCap, Monitor, Server, Shield, Users, Zap } from 'lucide-react';
import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { useToast } from '../../contexts/ToastContext';
import Button from '../common/Button';
import Card, { CardContent, CardHeader, CardTitle } from '../common/Card';
import Input from '../common/Input';

const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);

  const { login } = useAuth();
  const { showToast } = useToast();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      await login(email, password);
      showToast('Login successful!', 'success');
      
      // Wait a bit longer to ensure state is properly updated
      await new Promise(resolve => setTimeout(resolve, 500));
      
      const user = JSON.parse(localStorage.getItem('user') || '{}');
      console.log('Login successful, user role:', user.role);
      
      // Navigate based on role with proper error handling
      switch (user.role) {
        case 'STUDENT':
          console.log('Redirecting to student dashboard');
          navigate('/student');
          break;
        case 'PROFESSOR':
          console.log('Redirecting to professor dashboard');
          navigate('/professor');
          break;
        case 'MANAGEMENT':
          console.log('Redirecting to management dashboard');
          navigate('/management');
          break;
        case 'ALUMNI':
          console.log('Redirecting to alumni dashboard');
          navigate('/alumni');
          break;
        default:
          console.log('Unknown role:', user.role, 'redirecting to login');
          showToast('Invalid user role. Please contact support.', 'error');
          navigate('/login');
      }
    } catch (error: any) {
      console.error('Login error:', error);
      showToast(error.message || 'Login failed', 'error');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-primary-900 to-secondary-900 relative overflow-hidden">
      {/* Enhanced animated background elements */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-primary-500/20 rounded-full mix-blend-multiply filter blur-xl animate-pulse"></div>
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-secondary-500/20 rounded-full mix-blend-multiply filter blur-xl animate-pulse animate-bounce-subtle"></div>
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-60 h-60 bg-primary-400/15 rounded-full mix-blend-multiply filter blur-xl animate-pulse"></div>
      </div>

      {/* Floating tech icons - Enhanced with better positioning */}
      <div className="absolute inset-0 pointer-events-none hidden lg:block">
        <Code2 className="absolute top-20 left-20 w-6 h-6 text-primary-400/30 animate-float" />
        <Server className="absolute top-40 right-32 w-8 h-8 text-secondary-400/25 animate-float-delay-1" />
        <Database className="absolute bottom-32 left-32 w-7 h-7 text-primary-300/30 animate-float-delay-2" />
        <Monitor className="absolute bottom-20 right-20 w-6 h-6 text-secondary-300/30 animate-float" />
      </div>

      <div className="flex flex-col lg:flex-row min-h-screen relative z-10">
        {/* Left Content Section - Enhanced with professional cards */}
        <div className="hidden lg:flex lg:w-1/2 flex-col justify-center section-padding">
          <div className="max-w-lg mx-auto w-full space-y-8">
            {/* Enhanced Logo/Brand */}
            <div className="animate-fade-in">
              <h1 className="heading-primary mb-4">
                EduConnect
              </h1>
              <p className="text-xl text-white/80 mb-6 leading-relaxed">
                Empowering Educational Excellence Through Technology
              </p>
              <div className="w-24 h-1 bg-gradient-to-r from-primary-400 to-secondary-400 rounded-full"></div>
            </div>

            {/* Enhanced Features with professional cards */}
            <div className="space-y-4 animate-slide-up" style={{ animationDelay: '0.2s' }}>
              <Card variant="glass" padding="md" hover>
                <div className="flex items-center space-x-4">
                  <div className="bg-gradient-to-br from-primary-500 to-primary-600 p-3 rounded-xl shadow-glow">
                    <GraduationCap className="h-6 w-6 text-white" />
                  </div>
                  <div>
                    <CardTitle size="sm" className="mb-2">Smart Learning</CardTitle>
                    <CardContent className="text-sm">
                      AI-driven insights and personalized curriculum for enhanced learning outcomes
                    </CardContent>
                  </div>
                </div>
              </Card>

              <Card variant="glass" padding="md" hover>
                <div className="flex items-center space-x-4">
                  <div className="bg-gradient-to-br from-secondary-500 to-secondary-600 p-3 rounded-xl shadow-glow">
                    <Users className="h-6 w-6 text-white" />
                  </div>
                  <div>
                    <CardTitle size="sm" className="mb-2">Professional Network</CardTitle>
                    <CardContent className="text-sm">
                      Connect with industry professionals and expand your career opportunities
                    </CardContent>
                  </div>
                </div>
              </Card>

              <Card variant="glass" padding="md" hover>
                <div className="flex items-center space-x-4">
                  <div className="bg-gradient-to-br from-primary-400 to-secondary-500 p-3 rounded-xl shadow-glow">
                    <Briefcase className="h-6 w-6 text-white" />
                  </div>
                  <div>
                    <CardTitle size="sm" className="mb-2">Career Growth</CardTitle>
                    <CardContent className="text-sm">
                      Industry certifications and comprehensive job placement support
                    </CardContent>
                  </div>
                </div>
              </Card>
            </div>
          </div>
        </div>

        {/* Right Form Section - Enhanced with professional components */}
        <div className="flex-1 lg:w-1/2 flex items-center justify-center section-padding">
          <div className="w-full max-w-md mx-auto">
            {/* Mobile Logo - Enhanced */}
            <div className="lg:hidden text-center mb-8 animate-fade-in">
              <h1 className="heading-secondary mb-3">
                EduConnect
              </h1>
              <p className="text-white/80">
                Access your digital workspace
              </p>
            </div>

            {/* Enhanced login card */}
            <Card variant="default" padding="lg" className="animate-scale-in">
              <CardHeader className="text-center">
                <div className="mx-auto h-16 w-16 bg-gradient-to-br from-primary-500 to-secondary-600 rounded-2xl flex items-center justify-center mb-4 shadow-glow animate-pulse-glow">
                  <Shield className="h-8 w-8 text-white" />
                </div>
                <CardTitle size="lg" className="mb-2">
                  Welcome Back
                </CardTitle>
                <CardContent>
                  Access your EduConnect account and continue your learning journey
                </CardContent>
              </CardHeader>

              {/* Enhanced login form */}
              <form className="space-y-6" onSubmit={handleSubmit}>
                <Input
                  label="Email Address"
                  type="email"
                  required
                  placeholder="Enter your college email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  icon={Zap}
                  iconPosition="right"
                />

                <div className="relative">
                  <Input
                    label="Password"
                    type={showPassword ? 'text' : 'password'}
                    required
                    placeholder="Enter your password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                  />
                  <button
                    type="button"
                    className="absolute right-3 top-11 text-white/60 hover:text-white transition-colors"
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    {showPassword ? (
                      <EyeOff className="h-5 w-5" />
                    ) : (
                      <Eye className="h-5 w-5" />
                    )}
                  </button>
                </div>

                <Button
                  type="submit"
                  loading={loading}
                  fullWidth
                  icon={Shield}
                  iconPosition="left"
                  className="mt-8"
                >
                  {loading ? 'Authenticating...' : 'Sign In'}
                </Button>

                {/* Enhanced divider */}
                <div className="relative my-8">
                  <div className="absolute inset-0 flex items-center">
                    <div className="w-full border-t border-white/20"></div>
                  </div>
                  <div className="relative flex justify-center text-sm">
                    <span className="px-4 glass-soft rounded-lg text-white/70 text-sm">
                      New to the platform?
                    </span>
                  </div>
                </div>

                {/* Enhanced register link */}
                <div className="text-center">
                  <Link
                    to="/register"
                    className="group inline-flex items-center font-medium text-primary-300 hover:text-white transition-all duration-300 transform hover:scale-105"
                  >
                    Create your account
                    <Zap className="ml-2 h-4 w-4 group-hover:animate-pulse" />
                  </Link>
                </div>
              </form>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;
