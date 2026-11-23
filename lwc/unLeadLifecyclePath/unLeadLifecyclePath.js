import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import STATUS_FIELD from '@salesforce/schema/Lead.Status';
import IS_CONVERTED_FIELD from '@salesforce/schema/Lead.IsConverted';
import CONVERTED_OPP_FIELD from '@salesforce/schema/Lead.ConvertedOpportunityId';

const STAGES = [
    { label: 'New', apiName: 'New' },
    { label: 'Follow Up', apiName: 'Follow_Up' },
    { label: 'Site Visit Scheduled', apiName: 'SIte_Visit_Scheduled' },
    { label: 'Site Visit Completed', apiName: 'Site Visit Completed' },
    { label: 'Unqualified', apiName: 'Unqualified' },
    { label: 'Converted', apiName: 'Qualified', isConverted: true }
];

export default class UnLeadLifecyclePath extends NavigationMixin(LightningElement) {
    @api recordId;

    @track currentStatus = '';
    @track selectedStatus = '';
    @track isConverted = false;
    @track convertedOppId = null;
    @track showConvertModal = false;
    @track isUpdating = false;

    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD, IS_CONVERTED_FIELD, CONVERTED_OPP_FIELD] })
    wiredLead({ error, data }) {
        if (data) {
            this.currentStatus = getFieldValue(data, STATUS_FIELD) || '';
            this.isConverted = getFieldValue(data, IS_CONVERTED_FIELD) || false;
            this.convertedOppId = getFieldValue(data, CONVERTED_OPP_FIELD) || null;

            if (!this.selectedStatus) {
                this.selectedStatus = this.currentStatus;
            }
        } else if (error) {
            console.error('Error loading lead status:', error);
        }
    }

    get formattedStages() {
        const currentIndex = STAGES.findIndex(s => s.apiName === this.currentStatus);

        return STAGES.map((stage, idx) => {
            const isSelected = stage.apiName === this.selectedStatus;
            let cssClass = 'slds-path__item ';
            let iconVariant = 'bare';

            if (this.isConverted) {
                // If converted, all previous and converted stages are complete/won
                cssClass += 'slds-is-complete ';
            } else if (stage.apiName === this.currentStatus) {
                // Current stage (Dark Navy Blue)
                cssClass += 'slds-is-current ';
            } else if (idx < currentIndex) {
                // Completed stages (Teal/Green with checkmark)
                cssClass += 'slds-is-complete ';
            } else {
                // Future/Incomplete stages (Gray)
                cssClass += 'slds-is-incomplete ';
            }

            // User click selection state (White background with blue border)
            if (isSelected) {
                cssClass += 'slds-is-active ';
            }

            return {
                ...stage,
                isSelected,
                cssClass: cssClass.trim(),
                iconVariant
            };
        });
    }

    get isCurrentSelected() {
        return this.selectedStatus === this.currentStatus;
    }

    get isConvertedSelected() {
        return this.selectedStatus === 'Qualified';
    }

    get actionButtonLabel() {
        if (this.isConverted) {
            return 'Already Converted';
        }
        if (this.isConvertedSelected) {
            return 'Convert Lead';
        }
        if (this.isCurrentSelected) {
            return 'Mark Status as Complete';
        }
        return 'Mark as Current Status';
    }

    get isActionDisabled() {
        if (this.isUpdating) {
            return true;
        }
        if (this.isConverted) {
            return true;
        }
        return false;
    }

    get flowInputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    handleStageClick(event) {
        event.preventDefault();
        const value = event.currentTarget.dataset.value;
        if (value) {
            this.selectedStatus = value;
        }
    }

    handleActionClick() {
        // If Converted selected, open custom Screen Flow modal
        if (this.isConvertedSelected) {
            this.showConvertModal = true;
            return;
        }

        // If current status is selected, advance to next stage in sequence
        let targetStatus = this.selectedStatus;
        if (this.isCurrentSelected) {
            const curIdx = STAGES.findIndex(s => s.apiName === this.currentStatus);
            if (curIdx >= 0 && curIdx < STAGES.length - 1) {
                const nextStage = STAGES[curIdx + 1];
                if (nextStage.isConverted) {
                    // Next stage is converted, open Flow!
                    this.selectedStatus = nextStage.apiName;
                    this.showConvertModal = true;
                    return;
                }
                targetStatus = nextStage.apiName;
                this.selectedStatus = targetStatus;
            } else {
                return;
            }
        }

        // Update record via uiRecordApi
        this.isUpdating = true;
        const fields = {};
        fields.Id = this.recordId;
        fields.Status = targetStatus;

        updateRecord({ fields })
            .then(() => {
                const stageObj = STAGES.find(s => s.apiName === targetStatus);
                const label = stageObj ? stageObj.label : targetStatus;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Status Updated',
                        message: `Lead status changed to "${label}".`,
                        variant: 'success'
                    })
                );
                return notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            })
            .catch(error => {
                const msg = error.body ? error.body.message : error.message;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating status',
                        message: msg,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isUpdating = false;
            });
    }

    handleCloseModal() {
        this.showConvertModal = false;
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.showConvertModal = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Lead Converted!',
                    message: 'Lead has been converted successfully.',
                    variant: 'success'
                })
            );

            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

            // Refresh page so users see the converted state immediately
            setTimeout(() => {
                window.location.reload();
            }, 800);
        }
    }
}