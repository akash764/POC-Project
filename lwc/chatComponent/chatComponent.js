import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import listAllMessages from '@salesforce/apex/WhatsAppLWCService.listAllMessages';
import sendMessage from '@salesforce/apex/WhatsAppLWCService.sendMessage';

const POLL_MS = 10000;

export default class WhatsAppChat extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api phoneField = 'Phone';

    messageText = '';
    isSending = false;
    rawMessages = [];
    wiredResult;
    pollId;
    needsScroll = false;

    get recordFields() {
        return this.objectApiName ? [`${this.objectApiName}.${this.phoneField}`] : undefined;
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$recordFields' })
    record;

    get phone() {
        return this.record?.data?.fields?.[this.phoneField]?.value;
    }

    @wire(listAllMessages, { customerPhone: '$phone' })
    wiredMessages(result) {
        this.wiredResult = result;
        if (result.data) {
            if (result.data.length !== this.rawMessages.length) this.needsScroll = true;
            this.rawMessages = result.data;
        } else if (result.error) {
            this.toast('Error', result.error?.body?.message || 'Could not load messages', 'error');
        }
    }

    connectedCallback() {
        this.pollId = setInterval(() => {
            if (this.wiredResult) refreshApex(this.wiredResult);
        }, POLL_MS);
    }

    disconnectedCallback() {
        clearInterval(this.pollId);
    }

    renderedCallback() {
        if (this.needsScroll) {
            const area = this.template.querySelector('.chatArea');
            if (area) area.scrollTop = area.scrollHeight;
            this.needsScroll = false;
        }
    }

    get messages() {
        return this.rawMessages.map((m) => {
            const out = m.Outgoing__c;
            const who = out ? m.AgentName__c : m.Customer_Name__c;
            const when = m.Message_Sent_Time__c ? new Date(m.Message_Sent_Time__c).toLocaleString() : '';
            return {
                key: m.Id,
                itemClass: 'slds-chat-listitem ' + (out ? 'slds-chat-listitem_outbound' : 'slds-chat-listitem_inbound'),
                textClass: 'slds-chat-message__text ' + (out ? 'slds-chat-message__text_outbound' : 'slds-chat-message__text_inbound'),
                text: this.displayText(m),
                meta: [who, when].filter(Boolean).join(' • ')
            };
        });
    }

    displayText(m) {
        if (m.Message_Content__c) return m.Message_Content__c;
        if (m.Reaction__c) return 'Reacted ' + m.Reaction__c;
        if (m.Message_Type__c === 'image') return '📷 Image';
        return '[' + (m.Message_Type__c || 'message') + ']';
    }

    handleChange(event) {
        this.messageText = event.target.value;
    }

    handleKeyUp(event) {
        if (event.key === 'Enter') {
            this.messageText = event.target.value;
            this.handleSend();
        }
    }

    handleSend() {
        const text = (this.messageText || '').trim();
        if (!text || this.isSending) return;
        this.isSending = true;
        sendMessage({ customerPhone: this.phone, message: text })
            .then(() => {
                this.messageText = '';
                return refreshApex(this.wiredResult);
            })
            .catch((e) => this.toast('Send failed', e?.body?.message || 'Unknown error', 'error'))
            .finally(() => { this.isSending = false; });
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}