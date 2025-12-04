import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateTestData from '@salesforce/apex/TestDataGeneratorService.generateTestData';

export default class TestDataGenerator extends LightningElement {
    @track isGenerating = false;
    @track showResults = false;
    @track resultMessage = '';
    @track leadCount = 0;
    @track accountCount = 0;
    @track orderCount = 0;
    @track journalCount = 0;
    @track errorDetails = '';
    @track progressDetails = '';
    @track warningDetails = '';
    @track createdRecords = [];

    handleGenerateTestData() {
        this.isGenerating = true;
        this.showResults = false;
        this.resetResults();

        // Call Apex method
        generateTestData()
            .then(result => {
                this.isGenerating = false;
                
                if (result) {
                    this.showResults = true;
                    this.resultMessage = result.message || 'Test data generation completed';
                    this.leadCount = result.leadsCreated || 0;
                    this.accountCount = result.accountsCreated || 0;
                    this.orderCount = result.ordersCreated || 0;
                    this.journalCount = result.journalsCreated || 0;
                    
                    // Format error log
                    this.errorDetails = result.errorLog && result.errorLog.length > 0 
                        ? result.errorLog.join('\n') 
                        : '';
                    
                    // Format progress log
                    this.progressDetails = result.progressLog && result.progressLog.length > 0 
                        ? result.progressLog.join('\n') 
                        : '';
                    
                    // Format warning log
                    this.warningDetails = result.warningLog && result.warningLog.length > 0 
                        ? result.warningLog.join('\n') 
                        : '';
                    
                    // Build created records summary
                    this.buildCreatedRecordsSummary();
                    
                    if (result.isSuccess) {
                        // Show success toast
                        this.showToast('Success', 'Test data generated successfully!', 'success');
                    } else {
                        // Show error toast
                        this.showToast('Error', result.message || 'Failed to generate test data', 'error');
                    }
                } else {
                    this.handleUnexpectedError('No response received from server');
                }
            })
            .catch(error => {
                this.isGenerating = false;
                this.handleUnexpectedError(error);
            });
    }

    resetResults() {
        this.errorDetails = '';
        this.progressDetails = '';
        this.warningDetails = '';
        this.createdRecords = [];
        this.leadCount = 0;
        this.accountCount = 0;
        this.orderCount = 0;
        this.journalCount = 0;
    }

    handleUnexpectedError(error) {
        this.showResults = true;
        this.resultMessage = 'Unexpected error occurred during test data generation';
        
        let errorMessage = 'Unknown error';
        if (error) {
            if (typeof error === 'string') {
                errorMessage = error;
            } else if (error.body && error.body.message) {
                errorMessage = error.body.message;
            } else if (error.message) {
                errorMessage = error.message;
            } else {
                errorMessage = JSON.stringify(error);
            }
        }
        
        this.errorDetails = 'Error Details:\n' + errorMessage;
        
        // Show error toast
        this.showToast('Error', 'Failed to generate test data', 'error');
        
        console.error('TestDataGenerator Error:', error);
    }

    buildCreatedRecordsSummary() {
        this.createdRecords = [];
        
        if (this.leadCount > 0) {
            this.createdRecords.push({
                id: '1',
                type: 'Leads',
                count: this.leadCount,
                icon: 'standard:lead',
                description: `${this.leadCount} lead records with various market units and record types`
            });
        }
        
        if (this.accountCount > 0) {
            this.createdRecords.push({
                id: '2',
                type: 'PersonAccounts',
                count: this.accountCount,
                icon: 'standard:account',
                description: `${this.accountCount} person accounts converted from leads`
            });
        }
        
        if (this.orderCount > 0) {
            this.createdRecords.push({
                id: '3',
                type: 'Orders',
                count: this.orderCount,
                icon: 'standard:orders',
                description: `${this.orderCount} order records linked to person accounts`
            });
        }
        
        if (this.journalCount > 0) {
            this.createdRecords.push({
                id: '4',
                type: 'Journals',
                count: this.journalCount,
                icon: 'custom:custom63',
                description: `${this.journalCount} journal records with bidirectional order relationships`
            });
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: variant === 'error' ? 'sticky' : 'dismissible'
        });
        this.dispatchEvent(evt);
    }

    get isSuccess() {
        return this.showResults && !this.errorDetails;
    }

    get isError() {
        return this.showResults && this.errorDetails;
    }
    
    get hasWarnings() {
        return this.warningDetails && this.warningDetails.trim().length > 0;
    }
    
    get hasProgress() {
        return this.progressDetails && this.progressDetails.trim().length > 0;
    }
    
    get hasCreatedRecords() {
        return this.createdRecords && this.createdRecords.length > 0;
    }
    
    get totalRecordsCreated() {
        return this.leadCount + this.accountCount + this.orderCount + this.journalCount;
    }
}