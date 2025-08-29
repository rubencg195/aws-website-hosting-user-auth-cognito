import React, { useEffect, useState } from 'react';
import { Amplify } from 'aws-amplify';
import { signOut } from 'aws-amplify/auth';
import { withAuthenticator, Button, Heading, View, Card } from '@aws-amplify/ui-react';
import '@aws-amplify/ui-react/styles.css';

// Configure Amplify
Amplify.configure({
  Auth: {
    region: process.env.REACT_APP_AWS_REGION,
    userPoolId: process.env.REACT_APP_USER_POOL_ID,
    userPoolWebClientId: process.env.REACT_APP_USER_POOL_CLIENT_ID,
  }
});

function App({ signOut, user }) {
  const [userInfo, setUserInfo] = useState(null);

  useEffect(() => {
    if (user) {
      setUserInfo({
        username: user.username,
        email: user.attributes?.email,
        emailVerified: user.attributes?.email_verified,
        sub: user.attributes?.sub
      });
    }
  }, [user]);

  const handleSignOut = async () => {
    try {
      await signOut();
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  return (
    <View className="App">
      <Card>
        <Heading level={1}>Welcome to React Auth Demo!</Heading>
        <Heading level={3}>You are successfully authenticated</Heading>
        
        {userInfo && (
          <div style={{ margin: '20px 0', padding: '20px', backgroundColor: '#f5f5f5', borderRadius: '8px' }}>
            <h4>User Information:</h4>
            <p><strong>Username:</strong> {userInfo.username}</p>
            <p><strong>Email:</strong> {userInfo.email}</p>
            <p><strong>Email Verified:</strong> {userInfo.emailVerified ? 'Yes' : 'No'}</p>
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
    </View>
  );
}

export default withAuthenticator(App, {
  signUpAttributes: ['email'],
  socialProviders: [],
  variation: 'modal'
});
