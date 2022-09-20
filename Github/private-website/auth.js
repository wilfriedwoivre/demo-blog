const siteUrl = window.location.origin

const msalConfig = {
    auth: {
      clientId: "bd91bde3-ebdd-4610-b35e-6b22858d5564",
      authority: "https://login.microsoftonline.com/woivre.fr",
      redirectUri: siteUrl + "/login.html",
    },
    cache: {
      cacheLocation: "sessionStorage", // This configures where your cache will be stored
      storeAuthStateInCookie: false, // Set this to "true" if you are having issues on IE11 or Edge
    }
  };
  
  // Add here scopes for id token to be used at MS Identity Platform endpoints.
  const loginRequest = {
    scopes: ["openid", "profile", "User.Read"]
  };
  
  const myMSALObj = new Msal.UserAgentApplication(msalConfig);
  
  function signIn() {
    myMSALObj.loginPopup(loginRequest)
      .then(loginResponse => {
        console.log('id_token acquired at: ' + new Date().toString());
        console.log(loginResponse);
        window.location.href = siteUrl;
      }).catch(error => {
        console.log(error);
      });
  }