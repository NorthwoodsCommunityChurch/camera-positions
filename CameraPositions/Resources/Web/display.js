(function() {
    'use strict';

    let lastConfigJSON = null;

    async function fetchConfig() {
        try {
            const response = await fetch('/api/config');
            if (!response.ok) return null;
            const text = await response.text();
            if (!text || text === '{}') return null;
            return JSON.parse(text);
        } catch {
            return null;
        }
    }

    function render(config) {
        const container = document.getElementById('cameras');
        container.innerHTML = '';

        if (!config.cameras || config.cameras.length === 0) {
            container.innerHTML = '<div class="waiting"><p>No cameras configured</p></div>';
            return;
        }

        config.cameras.forEach(function(cam) {
            const col = document.createElement('div');
            col.className = 'camera-col';

            // Background photo: operator photo overrides angle photo
            var photoFilename = cam.operatorPhotoFilename || cam.anglePhotoFilename;
            if (photoFilename) {
                const img = document.createElement('img');
                img.className = 'angle-photo';
                img.src = '/api/images/' + photoFilename;
                img.alt = 'Camera ' + cam.number;
                col.appendChild(img);

                // Overlay for readability
                const overlay = document.createElement('div');
                overlay.className = 'overlay';
                col.appendChild(overlay);
            } else {
                col.classList.add('no-photo');
            }

            // Content layer (above photo)
            const content = document.createElement('div');
            content.className = 'content';

            // Center group: camera number + label, always dead center
            const centerGroup = document.createElement('div');
            centerGroup.className = 'center-group';

            const numDiv = document.createElement('div');
            numDiv.className = 'cam-number';
            numDiv.textContent = cam.number;
            centerGroup.appendChild(numDiv);

            // Label (if any)
            if (cam.label) {
                const labelDiv = document.createElement('div');
                labelDiv.className = 'cam-label';
                labelDiv.textContent = cam.label;
                centerGroup.appendChild(labelDiv);
            }

            content.appendChild(centerGroup);

            // Bottom section: lenses then name
            const bottom = document.createElement('div');
            bottom.className = 'bottom-info';

            // Lenses above the name
            if (cam.lenses && cam.lenses.length > 0) {
                const lensList = document.createElement('div');
                lensList.className = 'lens-list';

                cam.lenses.forEach(function(lens) {
                    const lensDiv = document.createElement('div');
                    lensDiv.className = 'lens-name';
                    lensDiv.textContent = lens.name;
                    lensList.appendChild(lensDiv);
                });

                bottom.appendChild(lensList);
            }

            // Operator name at the bottom
            if (cam.operatorName) {
                const nameDiv = document.createElement('div');
                nameDiv.className = 'operator-name';
                nameDiv.textContent = cam.operatorName;
                bottom.appendChild(nameDiv);
            } else {
                const emptyDiv = document.createElement('div');
                emptyDiv.className = 'operator-empty';
                emptyDiv.textContent = 'Unassigned';
                bottom.appendChild(emptyDiv);
            }

            content.appendChild(bottom);
            col.appendChild(content);
            container.appendChild(col);
        });
    }

    async function poll() {
        const config = await fetchConfig();
        const configJSON = JSON.stringify(config);

        if (config && configJSON !== lastConfigJSON) {
            lastConfigJSON = configJSON;
            render(config);
        }
    }

    // Clock
    function updateClock() {
        const now = new Date();
        var hours = now.getHours();
        var ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12 || 12;
        var minutes = now.getMinutes().toString().padStart(2, '0');
        var seconds = now.getSeconds().toString().padStart(2, '0');
        document.getElementById('clock').textContent = hours + ':' + minutes + ':' + seconds + ' ' + ampm;
    }

    // Poll every 5 seconds
    setInterval(poll, 5000);
    poll();

    // Update clock every second
    setInterval(updateClock, 1000);
    updateClock();
})();
