# Product Selector - Production Deployment Plan

**Created:** 8 December 2025  
**Target Org:** Production (00D1t000000w9f2)  
**Source Org:** Sandbox (mt@dinfamiliejurist.dk.itdevops)

---

## Summary of Changes

### New Features
- **Pricebook Icon Picker UI** - Visual card-based pricebook selection (replaces dropdown when 2+ pricebooks)
- **Premium Modal Styling** - Enhanced Create Payment modal with green gradient header
- **UI Polish** - Centered discount label, fixed Product Discounts icon

### Technical Changes
- New `Icon__c` field on `Price_Book__mdt`
- Apex wrapper updated to include icon data
- LWC updated with icon picker logic and styling

---

## Components to Deploy

### Custom Metadata Type: Price_Book__mdt

| Component | Type | Status |
|-----------|------|--------|
| `Price_Book__mdt` | Object Definition | ✅ Deployed |
| `Custom_Permission__c` | Field | ✅ Deployed |
| `Encoded_Private_Key__c` | Field | ✅ Deployed |
| `Icon__c` | Field (NEW) | ✅ Deployed |
| `Internal_Identifier__c` | Field | ✅ Deployed |
| `Test_Encoded_Private_Key__c` | Field | ✅ Deployed |

### CMDT Records

| Record | Status |
|--------|--------|
| `Price_Book.Din_Familiejurist` | ✅ Deployed |
| `Price_Book.DK_Pension` | ✅ Deployed |
| `Price_Book.Familjeavtal` | ✅ Deployed |
| `Price_Book.Heres_Law` | ✅ Deployed |

### Custom Permissions

| Custom Permission | Grants Access To | Status |
|-------------------|------------------|--------|
| `PriceBook_Din_Familiejurist` | Din Familiejurist pricebook | ✅ Deployed |
| `PriceBook_DK_Pension` | DK Pension pricebook | ✅ Deployed |
| `PriceBook_Famljeavtal` | Familjeavtal pricebook | ✅ Deployed |
| `PriceBook_Heres_Law` | Here's Law pricebook | ✅ Deployed |

### Permission Sets

| Permission Set | Purpose | Status |
|----------------|---------|--------|
| `PS_FEAT_ProductSelector` | General Product Selector access | ⬜ Deploy with Apex (Step 3) |
| `PS_PriceBook_DinFamiliejurist` | Grants DFJ pricebook access | ✅ Deployed |
| `PS_PriceBook_DKPension` | Grants DK Pension access | ✅ Deployed |
| `PS_PriceBook_Familjeavtal` | Grants Familjeavtal access | ✅ Deployed |
| `PS_PriceBook_HeresLaw` | Grants Here's Law access | ✅ Deployed |

### Apex Classes

| Class | Changes | Status |
|-------|---------|--------|
| `DFJProductController_Class.cls` | NEW - Added icon to wrapper, queries CMDT | ⬜ Not Deployed |
| `DFJProductService_Class.cls` | NEW - Product selector service layer | ⬜ Not Deployed |
| `DFJ_PaymentController.cls` | NEW - Payment controller | ⬜ Not Deployed |
| `PS_PaymentController.cls` | MODIFIED - Payment controller updates | ⬜ Not Deployed |
| `PS_PaymentService.cls` | MODIFIED - Payment service updates | ⬜ Not Deployed |
| `PS_PaymentUtility.cls` | MODIFIED - Payment utility updates | ⬜ Not Deployed |
| `PS_PaymentController_Test.cls` | MODIFIED - Test class updates | ⬜ Not Deployed |
| `PS_PaymentService_Test.cls` | MODIFIED - Test class updates | ⬜ Not Deployed |

### LWC Components

| Component | Changes | Status |
|-----------|---------|--------|
| `dfj_ProductSelectorCmp` | Icon picker UI, styling, discount label | ⬜ Not Deployed |
| `pS_EnhancedCreatePayment` | Premium modal styling | ⬜ Not Deployed |

### Flows

| Flow | Version | Status |
|------|---------|--------|
| `SF_Add_Bundle_Discounts` | v7 | ⬜ Not Deployed |

---

## Deployment Steps

### Step 1: Deploy CMDT, Custom Permissions, Permission Sets (except PS_FEAT_ProductSelector)
**Status:** ✅ Completed (8 Dec 2025)

*These are safe to deploy - no functional impact until Apex/LWC is deployed*

**Components:**
- [x] Price_Book__mdt (object + all fields)
- [x] Price_Book CMDT Records (4)
- [x] Custom Permissions (4)
- [x] Permission Sets (4 - excluding PS_FEAT_ProductSelector)

**Command:**
```bash
sf project deploy start \
  --source-dir force-app/main/default/objects/Price_Book__mdt \
  --source-dir force-app/main/default/customMetadata \
  --source-dir force-app/main/default/customPermissions \
  --source-dir force-app/main/default/permissionsets/PS_PriceBook_DinFamiliejurist.permissionset-meta.xml \
  --source-dir force-app/main/default/permissionsets/PS_PriceBook_DKPension.permissionset-meta.xml \
  --source-dir force-app/main/default/permissionsets/PS_PriceBook_Familjeavtal.permissionset-meta.xml \
  --source-dir force-app/main/default/permissionsets/PS_PriceBook_HeresLaw.permissionset-meta.xml \
  --target-org my-prod
```

**Notes:**
- Deploy ID: 0AfW5000001cj3ZKAQ
- PS_FEAT_ProductSelector deferred to Step 3 (requires Apex classes to exist first) 

---

### Step 2: Assign Permissions (Manual)
**Status:** ⬜ Not Started

*Must complete before Step 3*

**Tasks:**
- [ ] Assign `PS_FEAT_ProductSelector` to all Product Selector users
- [ ] Assign `PS_PriceBook_DinFamiliejurist` to DFJ users
- [ ] Assign `PS_PriceBook_DKPension` to DK Pension users
- [ ] Assign `PS_PriceBook_Familjeavtal` to Familjeavtal users
- [ ] Assign `PS_PriceBook_HeresLaw` to Here's Law users
- [ ] (Optional) Set Icon__c values on CMDT records for custom icons

**Notes:**
- 

---

### Step 3: Deploy Apex + PS_FEAT_ProductSelector
**Status:** ⬜ Not Started

**Components:**
- [ ] DFJProductController_Class.cls (NEW)
- [ ] DFJProductService_Class.cls (NEW)
- [ ] DFJ_PaymentController.cls (NEW)
- [ ] PS_PaymentController.cls (MODIFIED)
- [ ] PS_PaymentService.cls (MODIFIED)
- [ ] PS_PaymentUtility.cls (MODIFIED)
- [ ] PS_PaymentController_Test.cls (MODIFIED)
- [ ] PS_PaymentService_Test.cls (MODIFIED)
- [ ] PS_FEAT_ProductSelector.permissionset-meta.xml

**Command:**
```bash
sf project deploy start \
  --source-dir force-app/main/default/classes/DFJProductController_Class.cls \
  --source-dir force-app/main/default/classes/DFJProductController_Class.cls-meta.xml \
  --source-dir force-app/main/default/classes/DFJProductService_Class.cls \
  --source-dir force-app/main/default/classes/DFJProductService_Class.cls-meta.xml \
  --source-dir force-app/main/default/classes/DFJ_PaymentController.cls \
  --source-dir force-app/main/default/classes/DFJ_PaymentController.cls-meta.xml \
  --source-dir force-app/main/default/classes/PS_PaymentController.cls \
  --source-dir force-app/main/default/classes/PS_PaymentController.cls-meta.xml \
  --source-dir force-app/main/default/classes/PS_PaymentService.cls \
  --source-dir force-app/main/default/classes/PS_PaymentService.cls-meta.xml \
  --source-dir force-app/main/default/classes/PS_PaymentUtility.cls \
  --source-dir force-app/main/default/classes/PS_PaymentUtility.cls-meta.xml \
  --source-dir force-app/main/default/classes/PS_PaymentController_Test.cls \
  --source-dir force-app/main/default/classes/PS_PaymentController_Test.cls-meta.xml \
  --source-dir force-app/main/default/classes/PS_PaymentService_Test.cls \
  --source-dir force-app/main/default/classes/PS_PaymentService_Test.cls-meta.xml \
  --source-dir force-app/main/default/permissionsets/PS_FEAT_ProductSelector.permissionset-meta.xml \
  --target-org MyProd
```

**Notes:**
- PS_FEAT_ProductSelector requires Apex classes to exist, so deploying together 

---

### Step 4: Deploy LWC + Flow
**Status:** ⬜ Not Started

**Components:**
- [ ] dfj_ProductSelectorCmp
- [ ] pS_EnhancedCreatePayment
- [ ] SF_Add_Bundle_Discounts (Flow v8)

**Command:**
```bash
sf project deploy start \
  --source-dir force-app/main/default/lwc/dfj_ProductSelectorCmp \
  --source-dir force-app/main/default/lwc/pS_EnhancedCreatePayment \
  --source-dir force-app/main/default/flows/SF_Add_Bundle_Discounts.flow-meta.xml \
  --target-org MyProd
```

**Notes:**
- Flow SF_Add_Bundle_Discounts v7 retrieved from sandbox 

---

### Step 5: Post-Deployment Verification
**Status:** ⬜ Not Started

**Verification Tasks:**
- [ ] Test Product Selector on Lead record
- [ ] Test Product Selector on Opportunity record
- [ ] Verify pricebook icon picker displays (when 2+ pricebooks)
- [ ] Verify pricebook auto-selects (when only 1 pricebook)
- [ ] Verify Create Payment modal styling
- [ ] Verify discount label centered under button
- [ ] Verify Product Discounts icon displays in Order Summary

**Notes:**
- 

---

## Rollback Plan

**Backup Location:** `prod_backup/` folder (created 8 Dec 2025)

### What Was Backed Up From Production

| Component | Type | Status in Prod |
|-----------|------|----------------|
| `PS_PaymentController.cls` | ApexClass | ✅ Backed up |
| `PS_PaymentService.cls` | ApexClass | ✅ Backed up |
| `PS_PaymentUtility.cls` | ApexClass | ✅ Backed up |
| `PS_PaymentController_Test.cls` | ApexClass | ✅ Backed up |
| `PS_PaymentService_Test.cls` | ApexClass | ✅ Backed up |
| `pS_EnhancedCreatePayment` | LWC | ✅ Backed up |
| `SF_Add_Bundle_Discounts` | Flow | ✅ Backed up |
| `DFJProductController_Class.cls` | ApexClass | ❌ Does not exist (NEW) |
| `DFJProductService_Class.cls` | ApexClass | ❌ Does not exist (NEW) |
| `DFJ_PaymentController.cls` | ApexClass | ❌ Does not exist (NEW) |
| `dfj_ProductSelectorCmp` | LWC | ❌ Does not exist (NEW) |

### Rollback Commands

**If Step 3 (Apex) fails - Rollback modified Apex classes:**
```bash
sf project deploy start \
  --source-dir prod_backup/classes/PS_PaymentController.cls \
  --source-dir prod_backup/classes/PS_PaymentController.cls-meta.xml \
  --source-dir prod_backup/classes/PS_PaymentService.cls \
  --source-dir prod_backup/classes/PS_PaymentService.cls-meta.xml \
  --source-dir prod_backup/classes/PS_PaymentUtility.cls \
  --source-dir prod_backup/classes/PS_PaymentUtility.cls-meta.xml \
  --source-dir prod_backup/classes/PS_PaymentController_Test.cls \
  --source-dir prod_backup/classes/PS_PaymentController_Test.cls-meta.xml \
  --source-dir prod_backup/classes/PS_PaymentService_Test.cls \
  --source-dir prod_backup/classes/PS_PaymentService_Test.cls-meta.xml \
  --target-org MyProd
```

**If Step 4 (LWC) fails - Rollback LWC + Flow:**
```bash
sf project deploy start \
  --source-dir prod_backup/lwc/pS_EnhancedCreatePayment \
  --source-dir prod_backup/flows/SF_Add_Bundle_Discounts.flow-meta.xml \
  --target-org MyProd
```

### For NEW Components (Manual Deletion Required)

If you need to remove the NEW components that didn't exist before:

1. **NEW Apex Classes** - Delete via Setup → Apex Classes:
   - `DFJProductController_Class`
   - `DFJProductService_Class`
   - `DFJ_PaymentController`

2. **NEW LWC** - Delete via Setup → Lightning Components:
   - `dfj_ProductSelectorCmp`

### Notes
- CMDT, Custom Permissions, and Permission Sets (Step 1) do NOT need rollback - they have no functional impact without the Apex/LWC
- Step 2 (manual permission assignments) can be revoked manually if needed

---

## Deployment Log

| Date | Step | Deployed By | Result | Notes |
|------|------|-------------|--------|-------|
| 8 Dec 2025 | Step 1 | Copilot | ✅ Success | Deploy ID: 0AfW5000001cj3ZKAQ - CMDT, Custom Permissions, 4 Permission Sets |

