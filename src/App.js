import React, { useEffect, useState } from 'react';
import { Amplify } from 'aws-amplify';
import { Button, Heading, Card, TextField, Flex, Alert } from '@aws-amplify/ui-react';
import { signIn, signUp, confirmSignUp, getCurrentUser, signOut } from 'aws-amplify/auth';
import '@aws-amplify/ui-react/styles.css';

// Debug: Log environment variables
console.log('Environment variables:', {
  region: process.env.REACT_APP_AWS_REGION,
  userPoolId: process.env.REACT_APP_USER_POOL_ID,
  userPoolClientId: process.env.REACT_APP_USER_POOL_CLIENT_ID,
  cognitoDomain: process.env.REACT_APP_COGNITO_DOMAIN
});

// Configure Amplify v6
Amplify.configure({
  Auth: {
    Cognito: {
      userPoolId: process.env.REACT_APP_USER_POOL_ID,
      userPoolClientId: process.env.REACT_APP_USER_POOL_CLIENT_ID,
    region: process.env.REACT_APP_AWS_REGION,
      loginWith: {
        oauth: {
          domain: `${process.env.REACT_APP_COGNITO_DOMAIN}.auth.${process.env.REACT_APP_AWS_REGION}.amazoncognito.com`,
          scopes: ['email', 'openid', 'profile'],
          responseType: 'code',
        }
      }
    }
  }
});

function App() {
  const [user, setUser] = useState(null);
  const [userInfo, setUserInfo] = useState(null);
  const [authState, setAuthState] = useState('signIn'); // 'signIn', 'signUp', 'confirmSignUp', 'authenticated'
  const [formData, setFormData] = useState({ email: '', password: '', confirmPassword: '', code: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    checkAuthState();
  }, []);

  const checkAuthState = async () => {
    try {
      const currentUser = await getCurrentUser();
      setUser(currentUser);
      setUserInfo({
        username: currentUser.username,
        email: currentUser.signInDetails?.loginId,
        sub: currentUser.userId
      });
      setAuthState('authenticated');
    } catch (error) {
      setAuthState('signIn');
    }
  };

  const handleSignIn = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      await signIn({ username: formData.email, password: formData.password });
      await checkAuthState();
    } catch (error) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSignUp = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      await signUp({ username: formData.email, password: formData.password, options: { userAttributes: { email: formData.email } } });
      setAuthState('confirmSignUp');
    } catch (error) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleConfirmSignUp = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      await confirmSignUp({ username: formData.email, confirmationCode: formData.code });
      setAuthState('signIn');
      setFormData({ email: '', password: '', confirmPassword: '', code: '' });
    } catch (error) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSignOut = async () => {
    try {
      await signOut();
      setUser(null);
      setUserInfo(null);
      setAuthState('signIn');
      setFormData({ email: '', password: '', confirmPassword: '', code: '' });
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const renderSignIn = () => (
    <div style={{ 
      display: 'flex', 
      justifyContent: 'center', 
      alignItems: 'center', 
      minHeight: '100vh',
      padding: '20px',
      backgroundColor: '#f5f5f5'
    }}>
      <Card style={{ width: '100%', maxWidth: '400px' }}>
        <Heading level={3}>Sign In</Heading>
        <p style={{ color: '#666', marginBottom: '20px' }}>
          Sign in with your email address
        </p>
        
        {error && <Alert variation="error">{error}</Alert>}
        
        <form onSubmit={handleSignIn}>
          <Flex direction="column" gap="1rem">
            <TextField
              label="Email"
              type="email"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              required
            />
            <TextField
              label="Password"
              type="password"
              value={formData.password}
              onChange={(e) => setFormData({ ...formData, password: e.target.value })}
              required
            />
            <Button type="submit" variation="primary" isLoading={loading}>
              Sign In
            </Button>
            <Button type="button" variation="link" onClick={() => setAuthState('signUp')}>
              Don't have an account? Sign up
            </Button>
          </Flex>
        </form>
      </Card>
    </div>
  );

  const renderSignUp = () => (
    <div style={{ 
      display: 'flex', 
      justifyContent: 'center', 
      alignItems: 'center', 
      minHeight: '100vh',
      padding: '20px',
      backgroundColor: '#f5f5f5'
    }}>
      <Card style={{ width: '100%', maxWidth: '400px' }}>
        <Heading level={3}>Create Account</Heading>
        <p style={{ color: '#666', marginBottom: '20px' }}>
          Create your account using your email address
        </p>
        
        {error && <Alert variation="error">{error}</Alert>}
        
        <form onSubmit={handleSignUp}>
          <Flex direction="column" gap="1rem">
            <TextField
              label="Email"
              type="email"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              required
            />
            <TextField
              label="Password"
              type="password"
              value={formData.password}
              onChange={(e) => setFormData({ ...formData, password: e.target.value })}
              required
            />
            <TextField
              label="Confirm Password"
              type="password"
              value={formData.confirmPassword}
              onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
              required
            />
            <Button type="submit" variation="primary" isLoading={loading}>
              Sign Up
            </Button>
            <Button type="button" variation="link" onClick={() => setAuthState('signIn')}>
              Already have an account? Sign in
            </Button>
          </Flex>
        </form>
      </Card>
    </div>
  );

  const renderConfirmSignUp = () => (
    <div style={{ 
      display: 'flex', 
      justifyContent: 'center', 
      alignItems: 'center', 
      minHeight: '100vh',
      padding: '20px',
      backgroundColor: '#f5f5f5'
    }}>
      <Card style={{ width: '100%', maxWidth: '400px' }}>
        <Heading level={3}>Confirm Your Email</Heading>
        <p style={{ color: '#666', marginBottom: '20px' }}>
          Please check your email and enter the confirmation code
        </p>
        
        {error && <Alert variation="error">{error}</Alert>}
        
        <form onSubmit={handleConfirmSignUp}>
          <Flex direction="column" gap="1rem">
            <TextField
              label="Confirmation Code"
              value={formData.code}
              onChange={(e) => setFormData({ ...formData, code: e.target.value })}
              required
            />
            <Button type="submit" variation="primary" isLoading={loading}>
              Confirm
            </Button>
          </Flex>
        </form>
      </Card>
    </div>
  );

  const renderAuthenticated = () => (
    <div style={{ 
      display: 'flex', 
      justifyContent: 'center', 
      alignItems: 'center', 
      minHeight: '100vh',
      padding: '20px',
      backgroundColor: '#f5f5f5'
    }}>
      <Card style={{ width: '100%', maxWidth: '600px' }}>
        <Heading level={1}>Welcome to React Auth Demo!</Heading>
        <Heading level={3}>You are successfully authenticated</Heading>
        
        {userInfo && (
          <div style={{ margin: '20px 0', padding: '20px', backgroundColor: '#f5f5f5', borderRadius: '8px' }}>
            <h4>User Information:</h4>
            <p><strong>Username:</strong> {userInfo.username}</p>
            <p><strong>Email:</strong> {userInfo.email}</p>
            <p><strong>User ID:</strong> {userInfo.sub}</p>
          </div>
        )}

        <div style={{ margin: '20px 0' }}>
          <p>This is a protected page that only authenticated users can see.</p>
          <p>The authentication is handled by AWS Cognito and the app is hosted on AWS Amplify.</p>
        </div>

        <Button onClick={handleSignOut} variation="primary">
          Sign Out
        </Button>
      </Card>
    </div>
  );

  if (authState === 'signIn') return renderSignIn();
  if (authState === 'signUp') return renderSignUp();
  if (authState === 'confirmSignUp') return renderConfirmSignUp();
  if (authState === 'authenticated') return renderAuthenticated();

  return null;
}

export default App;
