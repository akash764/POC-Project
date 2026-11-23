import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CAMPAIGN_NAME_FIELD from '@salesforce/schema/Campaign.Name';

const BASE_SITE_URL = 'https://ajsd9--devsandbox.sandbox.my.site.com/UrbanNest/contact';

export default class UnCampaignQrCode extends LightningElement {
    @api recordId;
    @track copyButtonLabel = 'Copy Link';

    @wire(getRecord, { recordId: '$recordId', fields: [CAMPAIGN_NAME_FIELD] })
    campaign;

    get campaignName() {
        return getFieldValue(this.campaign.data, CAMPAIGN_NAME_FIELD) || 'Campaign';
    }

    get targetUrl() {
        return `${BASE_SITE_URL}?campaignId=${this.recordId || ''}`;
    }

    get qrImageUrl() {
        if (!this.recordId) {
            return '';
        }
        const encodedUrl = encodeURIComponent(this.targetUrl);
        return `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodedUrl}`;
    }

    async handleDownload() {
        try {
            const response = await fetch(this.qrImageUrl);
            const blob = await response.blob();
            const blobUrl = URL.createObjectURL(blob);
            const a = document.createElement('a');
            const sanitizedName = this.campaignName.replace(/[^a-zA-Z0-9_-]/g, '_');
            a.href = blobUrl;
            a.download = `UrbanNest_QR_${sanitizedName}.png`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(blobUrl);

            this.showToast('Downloaded!', 'QR Code image saved successfully.', 'success');
        } catch (e) {
            // Fallback: open image in a new tab for saving
            window.open(this.qrImageUrl, '_blank');
        }
    }

    handleCopyLink() {
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(this.targetUrl)
                .then(() => {
                    this.copyButtonLabel = 'Copied!';
                    this.showToast('Link Copied', 'Campaign URL copied to clipboard.', 'success');
                    setTimeout(() => {
                        this.copyButtonLabel = 'Copy Link';
                    }, 2500);
                })
                .catch(() => {
                    this.fallbackCopyText(this.targetUrl);
                });
        } else {
            this.fallbackCopyText(this.targetUrl);
        }
    }

    fallbackCopyText(text) {
        const textArea = document.createElement('textarea');
        textArea.value = text;
        document.body.appendChild(textArea);
        textArea.select();
        try {
            document.execCommand('copy');
            this.copyButtonLabel = 'Copied!';
            this.showToast('Link Copied', 'Campaign URL copied to clipboard.', 'success');
            setTimeout(() => {
                this.copyButtonLabel = 'Copy Link';
            }, 2500);
        } catch (err) {
            this.showToast('Error', 'Unable to copy URL.', 'error');
        }
        document.body.removeChild(textArea);
    }

    handleOpenUrl() {
        if (this.targetUrl) {
            window.open(this.targetUrl, '_blank');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
}