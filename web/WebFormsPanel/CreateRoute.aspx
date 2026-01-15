<%@ Page Title="Rota Oluştur" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="CreateRoute.aspx.cs" Inherits="WebFormsPanel.CreateRoute" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <style>
        #map {
            height: 500px;
            width: 100%;
            border-radius: 8px;
        }
        .stop-item {
            cursor: pointer;
            transition: all 0.3s;
        }
        .stop-item:hover {
            background-color: #f8f9fa;
        }
        .stop-item.selected {
            background-color: #e7f3ff;
            border-left: 4px solid #0d6efd;
        }
        .selected-stops-container {
            max-height: 400px;
            overflow-y: auto;
        }
        .draggable-stop {
            cursor: move;
            padding: 10px;
            margin: 5px 0;
            background: white;
            border: 1px solid #dee2e6;
            border-radius: 4px;
        }
        .draggable-stop:hover {
            background-color: #f8f9fa;
        }
    </style>
    <script src="https://maps.googleapis.com/maps/api/js?key=<%= System.Configuration.ConfigurationManager.AppSettings[\"GoogleMapsApiKey\"] %>&libraries=geometry&callback=initMap" async defer></script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="top-navbar">
        <h2><i class="bi bi-route"></i> Yeni Rota Oluştur</h2>
        <div>
            <button class="btn btn-secondary" onclick="window.location.href='Routes.aspx'">
                <i class="bi bi-arrow-left"></i> Geri
            </button>
        </div>
    </div>

    <div class="row">
        <!-- Sol Kolon: Tüm Duraklar -->
        <div class="col-md-4">
            <div class="card border-0 shadow-sm">
                <div class="card-header bg-white">
                    <h5 class="mb-0"><i class="bi bi-geo-alt"></i> Tüm Duraklar</h5>
                    <small class="text-muted">Durakları seçerek rotaya ekleyin</small>
                </div>
                <div class="card-body">
                    <div class="mb-3">
                        <input type="text" id="searchStop" class="form-control" placeholder="Durak ara...">
                    </div>
                    <div id="allStopsList" style="max-height: 500px; overflow-y: auto;">
                        <!-- JavaScript ile doldurulacak -->
                    </div>
                </div>
            </div>
        </div>

        <!-- Orta Kolon: Harita -->
        <div class="col-md-4">
            <div class="card border-0 shadow-sm">
                <div class="card-header bg-white">
                    <h5 class="mb-0"><i class="bi bi-map"></i> Rota Önizleme</h5>
                </div>
                <div class="card-body p-0">
                    <div id="map"></div>
                </div>
            </div>
        </div>

        <!-- Sağ Kolon: Seçilen Duraklar ve Rota Detayları -->
        <div class="col-md-4">
            <div class="card border-0 shadow-sm mb-3">
                <div class="card-header bg-white">
                    <h5 class="mb-0"><i class="bi bi-list-ol"></i> Rota Detayları</h5>
                </div>
                <div class="card-body">
                    <div class="mb-3">
                        <label class="form-label">Rota Adı</label>
                        <input type="text" id="routeName" class="form-control" placeholder="Örn: Sabah Rotası">
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Araç Seç</label>
                        <select id="vehicleSelect" class="form-select">
                            <option value="">Araç Seçin...</option>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Tahmini Başlangıç Saati</label>
                        <input type="time" id="startTime" class="form-control">
                    </div>
                </div>
            </div>

            <div class="card border-0 shadow-sm">
                <div class="card-header bg-white">
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <h5 class="mb-0"><i class="bi bi-list-check"></i> Seçilen Duraklar (<span id="selectedCount">0</span>)</h5>
                        <button type="button" id="optimizeBtn" class="btn btn-sm btn-success" onclick="optimizeRoute()" style="display: none;">
                            <i class="bi bi-arrows-collapse"></i> Optimize Et
                        </button>
                    </div>
                    <small class="text-muted">Sıralamayı değiştirmek için sürükleyin</small>
                </div>
                <div class="card-body selected-stops-container">
                    <div id="selectedStopsList">
                        <p class="text-muted text-center">Henüz durak seçilmedi</p>
                    </div>
                </div>
                <div class="card-footer bg-white">
                    <button type="button" id="createRouteBtn" class="btn btn-primary w-100" onclick="createRoute()">
                        <i class="bi bi-check-circle"></i> Rotayı Oluştur
                    </button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/sortablejs@latest/Sortable.min.js"></script>
    <script>
        const API_BASE_URL = 'http://localhost:5000';
        const AUTH_TOKEN = '<%= Session["AuthToken"] %>';
        let map;
        let markers = [];
        let polyline;
        let directionsRenderer;
        let directionsService;
        let allStops = [];
        let selectedStops = [];
        const urlParams = new URLSearchParams(window.location.search);
        const routeId = urlParams.get('routeId');
        let isEditMode = routeId !== null;

        // Harita başlat - Google Maps API callback fonksiyonu
        function initMap() {
            map = new google.maps.Map(document.getElementById('map'), {
                center: { lat: 39.9334, lng: 32.8597 },
                zoom: 12
            });

            // Directions service ve renderer
            directionsService = new google.maps.DirectionsService();
            directionsRenderer = new google.maps.DirectionsRenderer({
                map: map,
                suppressMarkers: true, // Kendi marker'larımızı kullanacağız
                polylineOptions: {
                    strokeColor: '#0d6efd',
                    strokeOpacity: 0.8,
                    strokeWeight: 4
                }
            });

            loadStops();
            loadVehicles();
            
            // Edit modundaysa rotayı yükle
            if (isEditMode) {
                loadRouteForEdit(routeId);
            }
        }

        // Haritayı güncelle
        function updateMap() {
            if (!map) return;

            // Eski markerları temizle
            markers.forEach(marker => marker.setMap(null));
            markers = [];

            // Tüm duraklar için marker ekle
            allStops.forEach(stop => {
                const isSelected = selectedStops.some(s => s.id === stop.id);
                
                const marker = new google.maps.Marker({
                    position: { lat: stop.latitude, lng: stop.longitude },
                    map: map,
                    title: stop.name,
                    icon: {
                        path: google.maps.SymbolPath.CIRCLE,
                        scale: isSelected ? 10 : 7,
                        fillColor: isSelected ? '#0d6efd' : '#6c757d',
                        fillOpacity: isSelected ? 1 : 0.6,
                        strokeColor: '#ffffff',
                        strokeWeight: 2
                    },
                    label: isSelected ? {
                        text: (selectedStops.findIndex(s => s.id === stop.id) + 1).toString(),
                        color: '#ffffff',
                        fontSize: '12px',
                        fontWeight: 'bold'
                    } : null
                });

                // Marker'a tıklandığında bilgi penceresi göster
                const infoWindow = new google.maps.InfoWindow({
                    content: `<div style="padding: 5px;">
                        <strong>${stop.name}</strong><br>
                        <small>${stop.userName || 'Bilinmeyen'}</small>
                    </div>`
                });

                marker.addListener('click', () => {
                    infoWindow.open(map, marker);
                });

                markers.push(marker);
            });

            // Seçilen duraklar için basit çizgi (optimize edilmeden önce)
            if (selectedStops.length >= 2) {
                if (!polyline) {
                    polyline = new google.maps.Polyline({
                        strokeColor: '#0d6efd',
                        strokeOpacity: 0.8,
                        strokeWeight: 3,
                        map: map
                    });
                }
                
                const path = selectedStops.map(stop => ({
                    lat: stop.latitude,
                    lng: stop.longitude
                }));

                polyline.setPath(path);

                // Haritayı tüm marker'ları gösterecek şekilde ayarla
                const bounds = new google.maps.LatLngBounds();
                selectedStops.forEach(stop => {
                    bounds.extend({ lat: stop.latitude, lng: stop.longitude });
                });
                map.fitBounds(bounds);
            } else if (selectedStops.length === 1) {
                // Tek durak varsa sadece o noktaya zoom yap
                map.setCenter({ lat: selectedStops[0].latitude, lng: selectedStops[0].longitude });
                map.setZoom(15);
                if (polyline) polyline.setPath([]);
            } else {
                if (polyline) polyline.setPath([]);
                
                // Eğer durak varsa hepsini göster
                if (allStops.length > 0) {
                    const bounds = new google.maps.LatLngBounds();
                    allStops.forEach(stop => {
                        bounds.extend({ lat: stop.latitude, lng: stop.longitude });
                    });
                    map.fitBounds(bounds);
                }
            }
        }

        // Gerçek yol çizimi (Directions API) - sadece optimize sonrası
        function drawRealRoute() {
            if (selectedStops.length < 2) return;

            const origin = { lat: selectedStops[0].latitude, lng: selectedStops[0].longitude };
            const destination = { lat: selectedStops[selectedStops.length - 1].latitude, lng: selectedStops[selectedStops.length - 1].longitude };
            
            // Ara duraklar (waypoints)
            const waypoints = selectedStops.slice(1, -1).map(stop => ({
                location: { lat: stop.latitude, lng: stop.longitude },
                stopover: true
            }));

            const request = {
                origin: origin,
                destination: destination,
                waypoints: waypoints,
                travelMode: google.maps.TravelMode.DRIVING,
                optimizeWaypoints: false
            };

            directionsService.route(request, (result, status) => {
                if (status === 'OK') {
                    // Basit çizgiyi gizle
                    if (polyline) polyline.setMap(null);
                    // Gerçek yolu göster
                    directionsRenderer.setDirections(result);
                } else {
                    console.error('Directions request failed:', status);
                }
            });
        }

        // Tüm durakları yükle
        function loadStops() {
            fetch(API_BASE_URL + '/api/stops/all', {
                headers: {
                    'Authorization': 'Bearer ' + AUTH_TOKEN
                }
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error('HTTP error! status: ' + response.status);
                }
                return response.json();
            })
            .then(stops => {
                allStops = stops;
                renderStopsList();
                updateMap();
            })
            .catch(error => {
                console.error('Duraklar yüklenemedi:', error);
                alert('Duraklar yüklenirken hata oluştu: ' + error.message);
            });
        }

        // Araçları yükle
        function loadVehicles() {
            fetch(API_BASE_URL + '/api/vehicles', {
                headers: {
                    'Authorization': 'Bearer ' + AUTH_TOKEN
                }
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error('HTTP error! status: ' + response.status);
                }
                return response.json();
            })
            .then(vehicles => {
                const select = document.getElementById('vehicleSelect');
                vehicles.forEach(vehicle => {
                    const option = document.createElement('option');
                    option.value = vehicle.id;
                    const driverInfo = vehicle.driverName ? vehicle.driverName : 'Şoför Atanmamış';
                    option.textContent = `${vehicle.plate} - ${driverInfo}`;
                    select.appendChild(option);
                });
            })
            .catch(error => console.error('Araçlar yüklenemedi:', error));
        }

        // Durak listesini render et
        function renderStopsList() {
            const container = document.getElementById('allStopsList');
            const searchTerm = document.getElementById('searchStop').value.toLowerCase();
            
            const filtered = allStops.filter(stop => 
                (stop.name || '').toLowerCase().includes(searchTerm) ||
                (stop.userName || '').toLowerCase().includes(searchTerm)
            );

            container.innerHTML = filtered.map(stop => `
                <div class="stop-item p-3 border-bottom ${selectedStops.some(s => s.id === stop.id) ? 'selected' : ''}" 
                     onclick="toggleStop(${stop.id})">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <strong><i class="bi bi-person"></i> ${stop.userName || 'Bilinmeyen'}</strong>
                            <br>
                            <small class="text-muted">
                                <i class="bi bi-geo-alt"> </i>${stop.name}
                            </small>
                        </div>
                        <div>
                            ${selectedStops.some(s => s.id === stop.id) 
                                ? '<i class="bi bi-check-circle-fill text-primary"></i>' 
                                : '<i class="bi bi-circle text-muted"></i>'}
                        </div>
                    </div>
                </div>
            `).join('');
        }

        // Durak seç/kaldır
        function toggleStop(stopId) {
            const stop = allStops.find(s => s.id === stopId);
            const index = selectedStops.findIndex(s => s.id === stopId);

            if (index === -1) {
                selectedStops.push(stop);
            } else {
                selectedStops.splice(index, 1);
            }

            renderStopsList();
            renderSelectedStops();
            updateMap();
        }

        // Seçilen durakları render et
        function renderSelectedStops() {
            const container = document.getElementById('selectedStopsList');
            document.getElementById('selectedCount').textContent = selectedStops.length;

            // Optimize butonunu göster/gizle
            const optimizeBtn = document.getElementById('optimizeBtn');
            optimizeBtn.style.display = selectedStops.length >= 2 ? 'block' : 'none';

            if (selectedStops.length === 0) {
                container.innerHTML = '<p class="text-muted text-center">Henüz durak seçilmedi</p>';
                return;
            }

            container.innerHTML = selectedStops.map((stop, index) => `
                <div class="draggable-stop" data-id="${stop.id}">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <i class="bi bi-grip-vertical text-muted"></i>
                            <strong>${index + 1}.</strong> ${stop.name}
                            <br>
                            <small class="text-muted">${stop.userName || 'Bilinmeyen'}</small>
                        </div>
                        <button class="btn btn-sm btn-outline-danger" onclick="removeStop(${stop.id})">
                            <i class="bi bi-x"></i>
                        </button>
                    </div>
                </div>
            `).join('');

            // Sıralamayı etkinleştir
            new Sortable(container, {
                animation: 150,
                onEnd: function(evt) {
                    const item = selectedStops.splice(evt.oldIndex, 1)[0];
                    selectedStops.splice(evt.newIndex, 0, item);
                    renderSelectedStops();
                    updateMap(); // Marker'ları güncelle
                    
                    // Eğer 2'den fazla durak varsa gerçek yolu yeniden çiz
                    if (selectedStops.length >= 2) {
                        drawRealRoute();
                    }
                }
            });
        }

        // Durağı kaldır
        function removeStop(stopId) {
            selectedStops = selectedStops.filter(s => s.id !== stopId);
            renderStopsList();
            renderSelectedStops();
            updateMap();
        }

        // Rotayı optimize et - Backend üzerinden Google Cloud Fleet Routing API
        async function optimizeRoute() {
            if (selectedStops.length < 2) {
                alert('En az 2 durak seçmelisiniz');
                return;
            }

            if (selectedStops.length === 2) {
                alert('İki durak için optimizasyon gerekmiyor.');
                return;
            }

            const optimizeBtn = document.getElementById('optimizeBtn');
            optimizeBtn.disabled = true;
            optimizeBtn.innerHTML = '<i class="bi bi-hourglass-split"></i> Rota Optimize Ediliyor...';

            console.log('Google Optimization API başladı, durak sayısı:', selectedStops.length);

            const requestData = {
                stops: selectedStops.map(stop => ({
                    id: stop.id,
                    name: stop.name,
                    latitude: stop.latitude,
                    longitude: stop.longitude
                }))
            };

            try {
                const response = await fetch(API_BASE_URL + '/api/routes/optimize', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer ' + AUTH_TOKEN
                    },
                    body: JSON.stringify(requestData)
                });

                if (!response.ok) {
                    const errorText = await response.text();
                    throw new Error(`API Error: ${response.status} - ${errorText}`);
                }

                const result = await response.json();
                console.log('Optimization API Response:', result);
                console.log('Gönderilen durak sayısı:', selectedStops.length);
                console.log('API dönen visit sayısı:', result.routes[0]?.visits?.length);

                if (result.routes && result.routes[0] && result.routes[0].visits) {
                    const visits = result.routes[0].visits;
                    
                    // Visit sayısı durak sayısına eşit mi kontrol et
                    if (visits.length !== selectedStops.length) {
                        console.warn(`Uyarı: ${selectedStops.length} durak gönderildi, ${visits.length} durak döndü!`);
                    }
                    
                    // Optimize edilmiş sıralamayı al
                    const optimizedStops = [];
                    const usedIndices = new Set();
                    
                    // Önce API'nin önerdiği sıralamayı ekle
                    visits.forEach(visit => {
                        console.log('Visit:', visit.shipmentIndex, selectedStops[visit.shipmentIndex]?.name);
                        if (visit.shipmentIndex !== undefined && selectedStops[visit.shipmentIndex]) {
                            optimizedStops.push(selectedStops[visit.shipmentIndex]);
                            usedIndices.add(visit.shipmentIndex);
                        }
                    });
                    
                    // API'nin atladığı durakları sonuna ekle
                    selectedStops.forEach((stop, index) => {
                        if (!usedIndices.has(index)) {
                            console.warn(`Durak ${index} (${stop.name}) API tarafından atlandı, sonuna ekleniyor`);
                            optimizedStops.push(stop);
                        }
                    });

                    // Toplam mesafe ve süre
                    const metrics = result.routes[0].metrics;
                    const totalDistance = metrics.travelDistanceMeters / 1000; // km
                    const totalDuration = parseInt(metrics.travelDuration.replace('s', '')) / 60; // dakika

                    console.log('Eski sıra:', selectedStops.map(s => s.name));
                    console.log('Yeni sıra:', optimizedStops.map(s => s.name));
                    console.log('Toplam mesafe:', totalDistance.toFixed(2), 'km');
                    console.log('Toplam süre:', totalDuration.toFixed(0), 'dakika');

                    // Sıralamayı güncelle
                    selectedStops.length = 0;
                    selectedStops.push(...optimizedStops);
                    
                    renderSelectedStops();
                    updateMap();
                    
                    // Optimize sonrası gerçek yolu çiz
                    drawRealRoute();
                    
                    alert(`✓ Rota optimize edildi!\n\nToplam Mesafe: ${totalDistance.toFixed(1)} km\nTahmini Süre: ${totalDuration.toFixed(0)} dakika`);
                } else {
                    throw new Error('Optimization sonucu alınamadı');
                }

            } catch (error) {
                console.error('Optimization hatası:', error);
                alert('Optimizasyon sırasında hata oluştu: ' + error.message);
            }
            
            optimizeBtn.disabled = false;
            optimizeBtn.innerHTML = '<i class="bi bi-arrows-collapse"></i> Optimize Et';
        }

        // Rotayı oluştur veya güncelle
        function createRoute() {
            const routeName = document.getElementById('routeName').value.trim();
            const vehicleId = document.getElementById('vehicleSelect').value;
            const startTime = document.getElementById('startTime').value;

            if (!routeName) {
                alert('Lütfen rota adı girin');
                return;
            }

            if (!vehicleId) {
                alert('Lütfen bir araç seçin');
                return;
            }

            if (selectedStops.length < 2) {
                alert('Lütfen en az 2 durak seçin');
                return;
            }

            const data = {
                Name: routeName,
                VehicleId: parseInt(vehicleId),
                StopIds: selectedStops.map(s => s.id),
                EstimatedStartTime: startTime ? new Date().toISOString().split('T')[0] + 'T' + startTime : null
            };

            document.getElementById('createRouteBtn').disabled = true;

            const url = isEditMode 
                ? API_BASE_URL + '/api/routes/' + routeId + '/update'
                : API_BASE_URL + '/api/routes/admin/create';
            
            const method = isEditMode ? 'PUT' : 'POST';

            fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ' + AUTH_TOKEN
                },
                body: JSON.stringify(data)
            })
            .then(response => {
                if (response.ok) {
                    alert(isEditMode ? 'Rota başarıyla güncellendi!' : 'Rota başarıyla oluşturuldu!');
                    window.location.href = 'Routes.aspx';
                } else {
                    return response.text().then(text => {
                        throw new Error(text);
                    });
                }
            })
            .catch(error => {
                alert('Hata: ' + error.message);
                document.getElementById('createRouteBtn').disabled = false;
            });
        }

        // Arama işlevi
        document.getElementById('searchStop').addEventListener('input', renderStopsList);

        // Rota bilgilerini yükle (edit modu)
        async function loadRouteForEdit(routeId) {
            try {
                // Rota detaylarını çek
                const routeResponse = await fetch(API_BASE_URL + '/api/routes/' + routeId, {
                    headers: {
                        'Authorization': 'Bearer ' + AUTH_TOKEN
                    }
                });

                if (!routeResponse.ok) throw new Error('Rota bilgileri alınamadı');
                const route = await routeResponse.json();

                // Rota durak bilgilerini çek
                const stopsResponse = await fetch(API_BASE_URL + '/api/routes/' + routeId + '/stops', {
                    headers: {
                        'Authorization': 'Bearer ' + AUTH_TOKEN
                    }
                });

                if (!stopsResponse.ok) throw new Error('Duraklar alınamadı');
                const routeStops = await stopsResponse.json();

                // Form alanlarını doldur
                document.getElementById('routeName').value = route.name || 'Rota #' + routeId;
                document.getElementById('vehicleSelect').value = route.vehicleId || '';
                
                if (route.estimatedStartTime) {
                    const startTime = new Date(route.estimatedStartTime);
                    const hours = String(startTime.getHours()).padStart(2, '0');
                    const minutes = String(startTime.getMinutes()).padStart(2, '0');
                    document.getElementById('startTime').value = hours + ':' + minutes;
                }

                // Sayfa başlığını güncelle
                document.querySelector('.top-navbar h2').innerHTML = '<i class="bi bi-pencil"></i> Rota Düzenle';
                document.getElementById('createRouteBtn').innerHTML = '<i class="bi bi-check-circle"></i> Rotayı Güncelle';

                // Durakları seçili yap
                routeStops.sort((a, b) => a.sequenceOrder - b.sequenceOrder).forEach(routeStop => {
                    const stop = allStops.find(s => s.id === routeStop.stopId);
                    if (stop && !selectedStops.some(s => s.id === stop.id)) {
                        selectedStops.push(stop);
                    }
                });

                renderStopsList();
                renderSelectedStops();
                updateMap();

            } catch (error) {
                console.error('Rota yükleme hatası:', error);
                alert('Rota bilgileri yüklenirken hata oluştu: ' + error.message);
            }
        }
    </script>
</asp:Content>
