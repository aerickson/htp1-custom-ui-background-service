<template>
  <div class="container">
    <div class="row mb-3">
      <div class="col">
        <h1>HTP-1 Background Service</h1>
        <div class="alert alert-primary" role="alert" v-if="updateVersion">
          <div class="row">
            <div class="col">Software version {{ updateVersion }} is ready to install.</div>
            <div class="col-auto">
              <button class="btn btn-sm btn-success" @click="requestInstallUpdate">
                Install Update
              </button>
            </div>
          </div>
        </div>
        <h2>Connect</h2>
        <form @submit.prevent="validateAndSetWebsocketurl(ipAddressText)">
          <div class="mb-3">
            <label for="htp1ip" class="form-label">HTP-1 IP Address</label>
            <input
              list="ipList"
              type="text"
              v-model="ipAddressText"
              class="form-control"
              id="htp1ip"
              aria-describedby="ipHelp"
            />
            <datalist id="ipList">
              <option v-for="ip in ipList" :value="ip" :key="ip" />
            </datalist>
            <div v-if="state === 'OPEN'" id="ipHelp" class="form-text text-success">
              Connected to {{ mso.unitname }}@{{ websocketIp }}.
            </div>
            <div v-else class="form-text">Not connected.</div>
          </div>
          <button
            type="submit"
            class="btn btn-primary mb-3"
            :disabled="ipAddressText === websocketIp"
          >
            Save
          </button>
        </form>
        <h2>Options</h2>
        <div class="form-check">
          <input
            class="form-check-input"
            type="checkbox"
            value=""
            id="run-on-startup"
            :checked="runOnSystemStartup"
            @change="toggleRunOnSystemStartup"
          />
          <label class="form-check-label" for="run-on-startup">Run on system startup</label>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col">
        <h2>Event Log</h2>
        <div class="table-responsive">
          <table class="table table-sm small">
            <thead>
              <tr>
                <th scope="col">Event</th>
                <!-- <th scope="col">Reason</th> -->
                <th scope="col">New Value</th>
                <th scope="col">Previous Value</th>
                <th scope="col">Time</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in eventLog" :key="item.time">
                <td>{{ item.event }}</td>
                <!-- <td>{{item.reason}}</td> -->
                <td>{{ item.new }}</td>
                <td>{{ item.old }}</td>
                <td>{{ item.time.toLocaleString() }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { onMounted, ref, watch, computed } from 'vue';

import useMso from '@/use/useMso.js';
import useWebSocket from '@/use/useWebSocket.js';
import useLocalStorage from '@/use/useLocalStorage.js';

export default {
  name: 'App',
  setup() {
    const { websocketIp, findServers, setWebsocketIp } = useWebSocket();
    const { runOnSystemStartup, toggleRunOnSystemStartup } = useLocalStorage();

    const {
      mso,
      state,
      setUpmix,
      upmixLabels,
      setLipsyncDelay,
      currentDiracSlot,
      setDiracSlot,
      resetBEQ,
      removeBEQActive,
      executeMacro,
    } = useMso();
    const ipAddressText = ref(websocketIp.value);
    const ipSet = ref(new Set());
    const ipList = ref([]);
    const updateVersion = ref(null);
    const eventLog = ref([]);

    onMounted(() => {
      if (websocketIp.value) {
        ipSet.value.add(websocketIp.value);
      }

      if (!websocketIp.value) {
        findServers(ipList.value, 4000);
      }

      window.ipcRenderer.receive('readyToInstall', (updateInfo) => {
        updateVersion.value = updateInfo.version;
      });
    });

    function validateAndSetWebsocketurl(url) {
      // todo: if valid
      setWebsocketIp(url);
    }

    function requestInstallUpdate() {
      window.ipcRenderer.send('installUpdateRequested');
    }

    function applyDefaultsForCurrentInput(reason) {
      // apply default upmix if one is defined
      if (
        currentInput?.value?.defaultUpmix &&
        currentInput?.value?.defaultUpmix !== mso.value.upmix.select
      ) {
        eventLog.value.unshift({
          event: `Apply Default Upmix for ${currentInput?.value?.label}`,
          reason: reason,
          old: upmixLabels[mso.value.upmix.select],
          new: upmixLabels[currentInput?.value?.defaultUpmix],
          time: new Date(),
        });

        setUpmix(currentInput?.value?.defaultUpmix);
      }

      // apply input delay if different from current delay
      if (
        typeof currentInput?.value?.delay === 'number' &&
        currentInput?.value?.delay !== mso?.value?.cal?.lipsync
      ) {
        eventLog.value.unshift({
          event: `Apply Delay for ${currentInput?.value?.label}`,
          reason: reason,
          old: `${mso?.value?.cal?.lipsync} ms`,
          new: `${currentInput?.value?.delay} ms`,
          time: new Date(),
        });

        setLipsyncDelay(currentInput?.value?.delay);
      }

      // apply dirac slot if needed
      if (
        typeof currentInput?.value?.diracslot === 'number' &&
        currentInput?.value?.diracslot !== mso.value.cal?.currentdiracslot
      ) {
        eventLog.value.unshift({
          event: `Apply Dirac Slot for ${currentInput?.value?.label}`,
          reason: reason,
          old: currentDiracSlot.value.name,
          new: mso.value.cal.slots[currentInput?.value?.diracslot].name,
          time: new Date(),
        });

        setDiracSlot(currentInput?.value?.diracslot);
      }

      // run input macro if needed
      if (typeof currentInput?.value?.macro === 'string') {
        const macro = getMacroCommands(currentInput?.value?.macro);

        if (macro) {
          eventLog.value.unshift({
            event: `Run Macro for ${currentInput?.value?.label}`,
            reason: reason,
            old: '--',
            new: mso?.value?.svronly?.macroNames[currentInput?.value?.macro],
            time: new Date(),
          });

          executeMacro(macro);
        }
      }

      // reset BEQ filters if needed
      for (const ch of ['sub1', 'sub2', 'sub3', 'sub4', 'sub5']) {
        for (let slot = 0; slot < 16; slot++) {
          if (mso.value.peq.slots[slot].channels[ch].beq) {
            resetBEQ(ch, slot);
          }
        }
      }

      if (mso.value.peq.beqActive) {
        eventLog.value.unshift({
          event: `Clear BEQ Filters`,
          reason: reason,
          old: mso.value.peq.beqActive,
          new: '',
          time: new Date(),
        });
        removeBEQActive();
      }

      while (eventLog.value.length > 50) {
        eventLog.value.pop();
      }
    }

    function getMacroCommands(macroId) {
      if (Object.prototype.hasOwnProperty.call(mso?.value?.svronly, macroId)) {
        return mso?.value?.svronly[macroId];
      }

      return mso?.value?.svronly.extraMacros[macroId];
    }

    const powerIsOn = computed(() => {
      return mso?.value?.powerIsOn;
    });

    const currentInput = computed(() => {
      if (mso?.value?.inputs) {
        return mso?.value?.inputs[mso?.value?.input];
      }

      return null;
    });

    watch(
      () => powerIsOn.value,
      (newPower, oldPower) => {
        applyDefaultsForCurrentInput('Power State Changed');
      }
    );

    watch(
      () => currentInput.value,
      (newInput, oldInput) => {
        if (mso && newInput?.label && oldInput?.label) {
          applyDefaultsForCurrentInput('Input Changed');
        }
      }
    );

    watch(state, () => {
      if (state.value === 'OPEN') {
        window.ipcRenderer.send('connected', true);
      } else {
        window.ipcRenderer.send('connected', false);
      }
    });

    watch(websocketIp, () => {
      ipAddressText.value = websocketIp.value;
    });

    watch(
      runOnSystemStartup,
      () => {
        window.ipcRenderer.send('runOnSystemStartupChanged', runOnSystemStartup.value);
      },
      {
        immediate: true,
      }
    );

    return {
      mso,
      powerIsOn,
      currentInput,
      state,
      websocketIp,
      ipAddressText,
      ipList,
      validateAndSetWebsocketurl,
      eventLog,
      updateVersion,
      requestInstallUpdate,
      runOnSystemStartup,
      toggleRunOnSystemStartup,
    };
  },
};
</script>

<style scoped></style>
