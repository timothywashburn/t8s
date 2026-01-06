# Authentik Setup

Authentik is installed automatically by this project, and it is recommended to use it for exposing the Longhorn dashboard. This guide will explain how to set up Authentik to work with Longhorn, but a similar process can be used to connect up any other application that uses OAuth/OIDC, SAML, LDAP, or other authentication and authentication protocols.

## Authentik + Longhorn Setup Instructions

### 1. Setup Initial Account

Do this by visiting `https://your.domain.com/if/flow/initial-setup/`. Use temporary information as the account will be disabled in the next step. If this doesn't work create a recovery code using:
```bash
kubectl exec -n authentik -it deployment/authentik-worker -- ak create_recovery_key 10 akadmin
```

### 2. Setup User Account

The default admin account has restrictions such as the inability to change its username, so it is recommended to immediately create another user account that can be elevated to admin, and then to disable this initial account.

1. Navigate to **Users**
2. Click **New User**
3. Configure the user:
   - **Username**: `<username>`
   - **Display Name**: `<display_name>`
   - **User type**: `Internal`
   - **Email Address**: `<email>`
4. Click **Create User**
5. Click on the **user**
6. Click **Set password** and set a password
7. Navigate to **Groups** → **Add to existing group**
8. Add the user to the `authentik Admins` group
9. Sign in to the **user account**
10. Navigate to **Users** → **akadmin**
11. Deactivate the `akadmin` user

### 3. Create an OAuth2/OIDC Provider

1. Log into Authentik admin interface
2. Navigate to **Applications** → **Providers**
3. Click **Create** and select **OAuth2/OpenID Provider**
4. Configure the provider:
   - **Name**: `longhorn`
   - **Authorization flow**: `default-provider-authorization-implicit-consent`
   - **Redirect URIs/Origins**: `https://<longhorn-host>/oauth2/callback`
5. Click **Finish**

### 4. Create an Application

1. Navigate to **Applications** → **Applications**
2. Click **Create**
3. Configure the application:
   - **Name**: `longhorn`
   - **Slug**: `longhorn`
   - **Provider**: `longhorn` (the previously created one)
4. Click **Create**

### 3. Copy OAuth Credentials

1. Navigate back to **Applications** → **Providers** → **longhorn**
2. Copy the following values:
   - **Client ID**
   - **Client Secret**

### 4. Generate Cookie Secret (OAuth2 Proxy Specific)

Generate the required cookie secret:

```bash
openssl rand -base64 32 | head -c 32
```

### 5. Update Cluster Configuration

Enable and fill in the longhorn ingress and authentication section of your cluster config.

Example configuration section:
```yaml
longhorn:
  ingress_and_auth:
    enabled: true
    oauth_client_id: <client-id-from-authentik>
    oauth_client_secret: <client-secret-from-authentik>
    cookie_secret: <generated-cookie-secret>
```

### 6. Deploy Changes

Re-run helmfile to apply the changes:

```bash
CLUSTER=<cluster-name> helmfile apply
```

## Additional Setup Configuration

### Configure Email Verification

OAuth2 Proxy (and possibly other services) requires the email to be verified, but this project does not provide a way to do this via normal methods. Instead, configure Authentik to show all emails as verified (this is fine as all user accounts will be manually created):

1. Navigate to **Customization** → **Property Mappings**
2. Disable the **Hide managed mappings** toggle
3. Find **authentik default OAuth Mapping: OpenID 'email'**
4. Click **Edit**
5. Modify the expression to always return `email_verified: True`:

```python
return {
    "email": request.user.email,
    "email_verified": True
}
```

6. Click **Update**