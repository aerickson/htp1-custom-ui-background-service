<template>
  <div
    id="settingsModal"
    class="modal fade show"
    tabindex="-1"
    aria-labelledby="settingsModalLabel"
  >
    <div class="modal-dialog modal-xl">
      <div class="modal-content bg-dark">
        <div class="modal-header text-white">
          <h4 class="modal-title">
            <template v-if="websocketIp"> Please Wait </template>
            <template v-else> Welcome </template>
          </h4>
        </div>
        <div class="modal-body text-left text-white">
          <template v-if="websocketIp">
            <p v-if="state === 'CONNECTING'">
              Connecting to {{ websocketIp }}...
              <span class="spinner-border text-primary" role="status">
                <span class="visually-hidden">Loading...</span>
              </span>
            </p>
            <p v-else>
              Connection to {{ websocketIp }} was lost. Reconnect will be attempted automatically.
              <span class="spinner-border text-primary" role="status">
                <span class="visually-hidden">Loading...</span>
              </span>
            </p>
            <p>Or, please update the IP address below if it has changed.</p>
          </template>
          <template v-else>
            <p>
              Now scanning the network for your HTP-1...
              <span class="spinner-border text-primary" role="status">
                <span class="visually-hidden">Loading...</span>
              </span>
            </p>
            <p>Or, please enter the local IP address for your HTP-1 below.</p>
          </template>

          <div class="form-group">
            <label for="select-ip" class="text-white">IP address</label>
            <input
              id="select-ip"
              v-model="ipAddressText"
              type="text"
              class="form-control form-control-sm text-white bg-dark"
              aria-describedby="ip-help"
              placeholder="e.g., 192.168.1.13"
            />
            <small id="ip-help" class="form-text"
              >Your entry will be remembered on this device.</small
            >
          </div>
          <div class="row justify-content-end">
            <div class="col-auto">
              <button
                class="btn btn-sm btn-primary"
                @click="validateAndSetWebsocketurl(ipAddressText)"
              >
                Save
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue';

import useWebSocket from '@/use/useWebSocket.js';

export default {
  name: 'IPSelect',
  setup() {
    const { websocketIp, websocketurl, setWebsocketIp, state } = useWebSocket();

    const ipAddressText = ref('');

    function validateAndSetWebsocketurl(url) {
      // todo: if valid
      setWebsocketIp(url);
    }

    return { ipAddressText, websocketIp, websocketurl, state, validateAndSetWebsocketurl };
  },
};
</script>

<style scoped>
div {
  color: #212529;
}

.modal {
  display: block;
}

.modal-header {
  border-bottom: 1px solid #212529;
}

.text-white {
  color: #dedad6 !important;
  /* background-color: #212529; */
}

input#select-ip.form-control.bg-dark {
  background-color: #212529 !important;
  border-color: rgba(255, 255, 255, 0.25);
}

small {
  color: rgba(255, 255, 255, 0.5) !important;
}
</style>
