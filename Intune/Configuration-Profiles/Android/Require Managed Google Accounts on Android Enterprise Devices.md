# Require Managed Google Accounts on Android Enterprise Devices
A practical deployment guide | Microsoft Intune, Android Enterprise & Google Workspace  
Published: October 21, 2026

Microsoft Intune now supports a policy that requires users on supported, corporate-owned Android Enterprise devices to authenticate with a managed Google Workspace account.

This capability helps organizations standardize the identity used to access Google services while retaining Microsoft Intune and Microsoft Entra ID for device management.

---

## 1. Understanding the Architecture

### Microsoft Entra ID & Intune
- Manage device configuration and security policies  
- Control application deployment and compliance  
- Provide Microsoft identity for organizational resources  

### Google Workspace
- Provides the managed Google account  
- Controls access to Google services  
- Administrators manage Google identities  

**Important:** This does *not* replace the Microsoft Entra identity.

---

## 2. Why Use This Policy?
Organizations benefit from:

- Consistent identity  
- Google Workspace access  
- Centralized Google account administration  
- Clear separation: Intune manages the device, Google manages the identity  

---

## 3. Supported Enrollment Types

| Enrollment type | Supported |
|-----------------|-----------|
| Corporate-owned, fully managed | ✅ Yes |
| Corporate-owned with a work profile | ✅ Yes |
| Dedicated devices (kiosk) | ❌ No |

---

## 4. Prerequisites

### Google Workspace
- Verified domain  
- Managed Google domain enterprise  
- Managed Google accounts for all targeted users  
- Required Google services enabled  
- Admin performing upgrade must be Super Admin  

### Microsoft Intune
- Tenant connected to Managed Google Play  
- Supported enrollment type  
- Policy & Profile Manager role  

---

## 5. Configure the Policy in Intune

### 1. Open Intune admin center  
Devices → Manage devices → Configuration → Create → New policy

### 2. Platform & profile  
- Platform: Android Enterprise  
- Profile type: Settings catalog  

### 3. Add setting  
Device restrictions → Users and Accounts →  
**Require users to authenticate with a Google Workspace account = True**

### 4. Assign  
Assign to a pilot group.

### 5. Review & create  
Confirm settings → Create.

---

## 6. User Experience

Flow:
1. Device receives policy  
2. User is prompted to sign in  
3. User authenticates with managed Google account  
4. Managed Google account replaces managed Google Play account  

**Important:**  
- Gmail may be disabled until authentication is completed  
- Policy may show *Error* until user signs in  

---

## 7. Verify Deployment

Check:
- Assignment status  
- Device check-in  
- Per-setting status  
- Account verification  

---

## 8. Troubleshooting

### Setting reports Error  
User has not completed authentication.

### User cannot authenticate  
- Account missing  
- Domain not verified  
- Workspace not upgraded  

### Policy not appearing  
- Wrong group  
- No check-in  
- Unsupported enrollment  
- Configuration not received  

### Gmail unavailable  
User has not authenticated yet.

---

## 9. Recommended Deployment Strategy
- Verify Google Workspace domain  
- Confirm managed Google accounts  
- Create pilot group  
- Assign policy  
- Validate authentication  
- Expand rollout  

---

## 10. Key Takeaways
This policy enables organizations to require a managed Google identity on corporate-owned Android devices without replacing Microsoft Entra ID.

**Recommendation:**  
Enable only if your organization uses Google Workspace.  
If you rely solely on Microsoft 365, the policy adds little value.

---

## Official Documentation
- Microsoft Intune — Android settings catalog  
- Microsoft Intune — Android enrollment guide  
- Managed Google Play connection  
- Google Workspace — Managed Google domain Android management
