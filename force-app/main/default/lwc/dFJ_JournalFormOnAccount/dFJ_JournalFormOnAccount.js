import { api, LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import MARKET_UNIT_FIELD from '@salesforce/schema/Account.Market_Unit__c';

import getJournalData_Apex from '@salesforce/apex/DFJ_JournalForm.getJournalData_Apex';
import journalAssociatedWithAccount from '@salesforce/apex/DFJ_JournalForm.journalAssociatedWithAccount';
import ordersAssociatedWithAccount from '@salesforce/apex/DFJ_JournalForm.ordersAssociatedWithAccount';
import getAccessibleOptions from '@salesforce/apex/DF_DocFabricator_Utility.getAccessibleOptions';
import getFormsForRecordModel from '@salesforce/apex/DF_DocFabricator_Utility.getFormsForRecordModel';

export default class DFJ_JournalFormOnAccount extends LightningElement {
    @api recordId;
    @api objectApiName;

    // Page layout configurable properties for two-tier selection
    @api recordModelIds = ''; // Comma-separated Record Model IDs (e.g., "160, 54, 22")
    @api formNumbers = ''; // Comma-separated Form Numbers (e.g., "17, 51, 22")
    @api buttonLabel = 'Create New Journal'; // Customizable button label
    @api buttonIcon = ''; // Optional icon for the button (e.g., "utility:add")

    // Internal state
    @track relatedOrders = [];
    selectedOrderId = '';
    createdJournalId = null;
    docFabFormUrl = null;
    isLoading = false;
    
    // Modal states
    isOrderSelectionModalOpen = false;
    isDocFabModalOpen = false;
    isIframeLoading = false;
    
    // Two-tier selection state
    isSelectionModalOpen = false;
    selectionStep = 'recordModel'; // 'recordModel' or 'form'
    recordModelOptions = [];
    formOptions = [];
    selectedRecordModelId = null;
    selectedFormUuid = null;
    fieldConfigurationJson = null;
    isFetchingForm = false;

    // Wire account data to get Market Unit
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [MARKET_UNIT_FIELD]
    })
    accountData;

    get marketUnit() {
        return this.accountData?.data ? getFieldValue(this.accountData.data, MARKET_UNIT_FIELD) : null;
    }

    get buttonIconName() {
        return this.buttonIcon || 'utility:add';
    }

    get hasOrders() {
        return this.relatedOrders && this.relatedOrders.length > 0;
    }

    get orderOptions() {
        if (!this.relatedOrders) return [];
        return this.relatedOrders.map(order => ({
            label: `${order.Account?.Name || 'Order'}: Value - ${order.Provision_Value__c || 'N/A'}`,
            value: order.Id
        }));
    }

    get isFormLoading() {
        return this.isFetchingForm || this.isIframeLoading;
    }

    // ========== Selection Modal Getters ==========
    get selectionModalTitle() {
        return this.selectionStep === 'recordModel' ? 'Select Journal Type' : 'Select Form View';
    }

    get selectionModalSubtitle() {
        return this.selectionStep === 'recordModel' 
            ? 'Choose which type of journal you want to create'
            : 'Choose how you want to view this journal';
    }

    get selectionModalIcon() {
        return this.selectionStep === 'recordModel' ? 'standard:form' : 'standard:article';
    }

    get showRecordModelSelection() {
        return this.selectionStep === 'recordModel';
    }

    get showFormSelection() {
        return this.selectionStep === 'form';
    }

    get showBackButton() {
        return this.selectionStep === 'form' && this.recordModelOptions.length > 1;
    }

    get currentFormOptions() {
        if (!this.selectedRecordModelId) {
            return this.formOptions;
        }
        return this.formOptions.filter(f => f.recordModelId === this.selectedRecordModelId);
    }

    // ========== Button Click Handler ==========
    async handleCreateJournalClick() {
        if (this.isLoading) return;
        
        this.isLoading = true;
        
        try {
            // Fetch related orders for the account
            const orders = await ordersAssociatedWithAccount({ recordId: this.recordId });
            this.relatedOrders = orders || [];
            
            // Show order selection modal
            this.isOrderSelectionModalOpen = true;
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // ========== Order Selection Handlers ==========
    handleOrderChange(event) {
        this.selectedOrderId = event.detail.value;
    }

    handleOrderSelectionCancel() {
        this.isOrderSelectionModalOpen = false;
        this.selectedOrderId = '';
    }

    async handleConfirmCreateJournal() {
        this.isOrderSelectionModalOpen = false;
        this.isLoading = true;
        
        try {
            console.log('=== handleConfirmCreateJournal ===');
            console.log('recordModelIds:', this.recordModelIds);
            console.log('formNumbers:', this.formNumbers);
            
            // Fetch accessible options based on page layout config
            const options = await getAccessibleOptions({
                recordModelIdsCsv: this.recordModelIds || '',
                formNumbersCsv: this.formNumbers || ''
            });

            console.log('getAccessibleOptions result:', JSON.stringify(options));

            if (!options) {
                throw new Error('No DocFab configuration found for this page layout.');
            }

            // Store options for selection
            this.recordModelOptions = options.recordModels || [];
            this.formOptions = options.forms || [];

            console.log('recordModelOptions:', this.recordModelOptions.length);
            console.log('formOptions:', this.formOptions.length);
            console.log('requiresRecordModelSelection:', options.requiresRecordModelSelection);
            console.log('requiresFormSelection:', options.requiresFormSelection);
            console.log('resolvedRecordModelId:', options.resolvedRecordModelId);

            if (this.recordModelOptions.length === 0) {
                throw new Error('You do not have permission to create any journal types on this page.');
            }

            // Determine what to show
            if (!options.requiresRecordModelSelection && !options.requiresFormSelection) {
                // Direct - only one option available
                console.log('Path: Direct open');
                this.selectedRecordModelId = options.resolvedRecordModelId;
                this.selectedFormUuid = options.resolvedFormUuid;
                this.fieldConfigurationJson = options.fieldConfigurationJson;
                await this.createJournalAndOpenForm();
            } else if (!options.requiresRecordModelSelection && options.requiresFormSelection) {
                // Skip record model selection, show form picker
                console.log('Path: Form selection only');
                this.selectedRecordModelId = options.resolvedRecordModelId;
                this.fieldConfigurationJson = options.fieldConfigurationJson;
                this.selectionStep = 'form';
                this.isSelectionModalOpen = true;
            } else {
                // Show record model picker first
                console.log('Path: Record model selection');
                this.selectionStep = 'recordModel';
                this.isSelectionModalOpen = true;
            }
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // ========== Record Model / Form Selection Handlers ==========
    async handleRecordModelSelect(event) {
        const recordModelId = event.currentTarget.dataset.id;
        console.log('=== handleRecordModelSelect ===');
        console.log('recordModelId from click:', recordModelId);
        if (!recordModelId) return;

        this.selectedRecordModelId = recordModelId;
        console.log('selectedRecordModelId set to:', this.selectedRecordModelId);
        this.isFetchingForm = true;

        try {
            // Get forms for this record model
            const options = await getFormsForRecordModel({
                recordModelId: recordModelId,
                formNumbersCsv: this.formNumbers || ''
            });

            console.log('getFormsForRecordModel result:', JSON.stringify(options));

            if (options && options.forms && options.forms.length > 0) {
                this.formOptions = options.forms;
                this.fieldConfigurationJson = options.fieldConfigurationJson;

                if (options.forms.length === 1) {
                    // Only one form, auto-select and proceed
                    console.log('Only 1 form, auto-selecting');
                    this.selectedFormUuid = options.forms[0].formUuid;
                    this.isSelectionModalOpen = false;
                    await this.createJournalAndOpenForm();
                } else {
                    // Multiple forms, show form selection
                    console.log('Multiple forms, showing form selection');
                    this.selectionStep = 'form';
                }
            } else {
                throw new Error('No forms available for the selected journal type.');
            }
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isFetchingForm = false;
        }
    }

    async handleFormSelect(event) {
        const formUuid = event.currentTarget.dataset.id;
        if (!formUuid) return;

        this.selectedFormUuid = formUuid;
        this.isSelectionModalOpen = false;
        await this.createJournalAndOpenForm();
    }

    handleBackToRecordModels() {
        this.selectionStep = 'recordModel';
        this.selectedFormUuid = null;
    }

    handleSelectionModalClose() {
        this.isSelectionModalOpen = false;
        this.selectionStep = 'recordModel';
        this.selectedRecordModelId = null;
        this.selectedFormUuid = null;
    }

    // ========== Journal Creation & Form Opening ==========
    async createJournalAndOpenForm() {
        console.log('=== createJournalAndOpenForm ===');
        console.log('selectedRecordModelId:', this.selectedRecordModelId);
        console.log('selectedFormUuid:', this.selectedFormUuid);
        console.log('selectedOrderId:', this.selectedOrderId);
        
        this.isLoading = true;
        this.isIframeLoading = true;

        try {
            // Step 1: Create the journal record with the selected Record Model ID
            console.log('Calling journalAssociatedWithAccount with:', {
                recordId: this.recordId,
                orderId: this.selectedOrderId || '',
                recordModelId: this.selectedRecordModelId || ''
            });
            
            const journals = await journalAssociatedWithAccount({
                recordId: this.recordId,
                orderId: this.selectedOrderId || '',
                recordModelId: this.selectedRecordModelId || ''
            });

            console.log('Journal created:', journals);

            if (!journals || journals.length === 0) {
                throw new Error('Failed to create journal record.');
            }

            this.createdJournalId = journals[0].Id;
            console.log('createdJournalId:', this.createdJournalId);

            // Step 2: Get the DocFab URL using the new parameters
            // Convert selectedRecordModelId to number for Apex (expects Decimal)
            const recordModelIdNum = this.selectedRecordModelId ? parseInt(this.selectedRecordModelId, 10) : null;
            
            console.log('Calling getJournalData_Apex with:', {
                JournalId: this.createdJournalId,
                objectName: 'Account',
                contextRecordId: this.recordId,
                journlaFormClicked: true,
                componentRecordModelId: recordModelIdNum,
                componentFormUuid: this.selectedFormUuid || null,
                componentFormTypeName: null
            });
            
            const result = await getJournalData_Apex({
                JournalId: this.createdJournalId,
                objectName: 'Account',
                contextRecordId: this.recordId,
                journlaFormClicked: true,
                componentRecordModelId: recordModelIdNum,
                componentFormUuid: this.selectedFormUuid || null,
                componentFormTypeName: null
            });

            console.log('getJournalData_Apex result:', result);

            if (result && result.docFabUrl) {
                const url = result.docFabUrl;
                console.log('DocFab URL:', url);
                
                // Check for error messages in the URL response
                if (url.includes('Current user with') || 
                    url.includes('No form configuration found') || 
                    url.includes('Can not open') || 
                    url.includes('Can not create') || 
                    url.includes('Error') ||
                    url.includes('Record Model ID is required')) {
                    this.showToast('Error', url, 'error', 'sticky');
                } else {
                    this.docFabFormUrl = url;
                    this.isDocFabModalOpen = true;
                }
            } else {
                throw new Error('Failed to get DocFab form URL.');
            }

            // Notify that the record was updated (LWC way to refresh related lists)
            if (this.createdJournalId) {
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            }
            
        } catch (error) {
            console.log('Error in createJournalAndOpenForm:', error);
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
            this.selectedOrderId = '';
        }
    }

    // ========== DocFab Modal Handlers ==========
    handleIframeLoad() {
        this.isIframeLoading = false;
    }

    handleCloseDocFabModal() {
        this.isDocFabModalOpen = false;
        this.docFabFormUrl = null;
        this.isIframeLoading = false;
    }

    // ========== Utility Methods ==========
    showToast(title, message, variant, mode = 'dismissable') {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
            mode
        }));
    }

    extractErrorMessage(error) {
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return 'An unexpected error occurred.';
    }
}