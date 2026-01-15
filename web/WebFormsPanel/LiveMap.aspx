<%@ Page Title="Canlı Harita" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="LiveMap.aspx.cs" Inherits="WebFormsPanel.LiveMap" Async="true" EnableEventValidation="false" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <style>
        .top-navbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 24px;
        }

        .top-navbar h2 {
            margin: 0;
            font-weight: 600;
            color: #2c3e50;
        }

        #map {
            height: 75vh;
            border-radius: 12px;
            width: 100%;
        }

        .vehicle-item {
            display: block;
            padding: 16px;
            text-decoration: none;
            color: inherit;
            border-bottom: 1px solid #f1f1f1;
            transition: all 0.2s;
        }

        .vehicle-item:hover {
            background-color: #f8f9fa;
        }

        .vehicle-item.active {
            background-color: #e7f3ff;
            border-left: 3px solid #0d6efd;
        }

        .vehicle-badge-moving {
            background-color: #198754;
        }

        .vehicle-badge-stopped {
            background-color: #fd7e14;
        }

        .vehicle-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            border-radius: 999px;
            color: #fff;
            font-size: 12px;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="top-navbar">
        <h2><i class="bi bi-map"></i> Canlı Harita</h2>
        <button type="button" class="btn btn-sm btn-primary" id="refreshBtn">
            <i class="bi bi-arrow-clockwise"></i> Yenile
        </button>
    </div>

    <div class="row g-4">
        <div class="col-md-9">
            <div class="card border-0 shadow-sm">
                <div class="card-body p-0">
                    <div id="map"></div>
                </div>
            </div>
        </div>

        <div class="col-md-3">
            <div class="card border-0 shadow-sm">
                <div class="card-header bg-white border-bottom-0">
                    <h5 class="mb-0"><i class="bi bi-list-ul"></i> Aktif Araçlar</h5>
                </div>
                <div class="card-body p-0">
                    <div class="list-group list-group-flush" style="max-height: 65vh; overflow-y: auto;">
                        <asp:Repeater ID="rptVehicleList" runat="server">
                            <ItemTemplate>
                                <a href="#" class="list-group-item list-group-item-action vehicle-item" 
                                   data-lat="<%# Eval("Latitude") %>" 
                                   data-lng="<%# Eval("Longitude") %>"
                                   data-id="<%# Eval("Id") %>">
                                    <div class="d-flex align-items-start">
                                        <div class="flex-shrink-0">
                                            <i class="bi bi-bus-front-fill text-primary" style="font-size: 24px;"></i>
                                        </div>
                                        <div class="flex-grow-1 ms-3">
                                            <div class="d-flex justify-content-between align-items-center">
                                                <strong><%# Eval("PlateNumber") %></strong>
                                                <span class="vehicle-badge <%# GetStatusBadgeClass(Eval("Status")) %>">
                                                    <i class="bi bi-circle-fill" style="font-size: 10px;"></i>
                                                    <%# GetStatusText(Eval("Status")) %>
                                                </span>
                                            </div>
                                            <small class="text-muted d-block"><%# Eval("RouteName") %></small>
                                            <small class="text-muted d-block mt-1"><i class="bi bi-person"></i> <%# Eval("DriverName") %></small>
                                            <small class="text-muted d-block mt-1"><i class="bi bi-people"></i> <%# Eval("PassengerCount") %> yolcu</small>
                                            <small class="text-muted d-block mt-1"><i class="bi bi-clock"></i> <%# Eval("LastUpdate", "{0:HH:mm:ss}") %></small>
                                        </div>
                                    </div>
                                </a>
                            </ItemTemplate>
                        </asp:Repeater>

                        <asp:PlaceHolder ID="phNoVehicles" runat="server" Visible="false">
                            <div class="text-center py-5 text-muted">
                                <i class="bi bi-inbox" style="font-size: 48px;"></i>
                                <p class="mt-3 mb-0">Aktif araç bulunmamaktadır.</p>
                            </div>
                        </asp:PlaceHolder>
                    </div>
                </div>
            </div>

            <div class="card border-0 shadow-sm mt-3">
                <div class="card-header bg-white border-bottom-0">
                    <h5 class="mb-0"><i class="bi bi-info-circle"></i> İstatistikler</h5>
                </div>
                <div class="card-body">
                    <div class="d-flex justify-content-between mb-2">
                        <small>Toplam Araç</small>
                        <strong><asp:Label ID="lblTotalVehicles" runat="server" Text="0"></asp:Label></strong>
                    </div>
                    <div class="d-flex justify-content-between mb-2">
                        <small>Hareket Halinde</small>
                        <strong class="text-success"><asp:Label ID="lblMovingVehicles" runat="server" Text="0"></asp:Label></strong>
                    </div>
                    <div class="d-flex justify-content-between">
                        <small>Durmuş Araç</small>
                        <strong class="text-warning"><asp:Label ID="lblStoppedVehicles" runat="server" Text="0"></asp:Label></strong>
                    </div>
                </div>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="scripts" runat="server">
    <!-- SignalR Client Library -->
    <script src="https://cdn.jsdelivr.net/npm/@microsoft/signalr@latest/dist/browser/signalr.min.js"></script>
    
    <script>
        let map;
        let markers = {};
        let infoWindows = {};
        let signalRConnection;
        let followedVehicleId = null; // Takip edilen araç ID'si
        let routeMarkers = []; // Rota durakları için marker'lar
        let routePolyline = null; // Rota çizgisi
        const vehicleData = <asp:Literal ID="litVehiclesJson" runat="server"></asp:Literal>;
        const API_BASE_URL = '<%= ConfigurationManager.AppSettings["ApiBaseUrl"] ?? "http://localhost:5000" %>';
        const routeIdParam = new URLSearchParams(window.location.search).get('routeId');

        // Sayfa yüklendiğinde
        window.onload = async function() {
            // Eğer routeId parametresi varsa, o rotayı göster
            if (routeIdParam) {
                await loadRouteOnMap(routeIdParam);
            }
        };

        // SignalR Bağlantısı Kur
        async function initSignalR() {
            try {
                const signalRUrl = API_BASE_URL.replace('/api/', '').replace('/api', '') + '/hubs/location';
                console.log('🔗 SignalR URL:', signalRUrl);
                signalRConnection = new signalR.HubConnectionBuilder()
                    .withUrl(signalRUrl, {
                        skipNegotiation: true,
                        transport: signalR.HttpTransportType.WebSockets
                    })
                    .withAutomaticReconnect()
                    .configureLogging(signalR.LogLevel.Information)
                    .build();

                // Konum güncellemelerini dinle
                signalRConnection.on("ReceiveLocationUpdate", function (location) {
                    console.log('📍 Location update received:', location);
                    updateVehicleMarker(location);
                });

                // Rota durumu güncellemelerini dinle
                signalRConnection.on("ReceiveRouteStatusUpdate", function (update) {
                    console.log('🚦 Route status update:', update);
                });

                // Durak varış bildirimlerini dinle
                signalRConnection.on("ReceiveStopArrival", function (info) {
                    console.log('🏁 Stop arrival:', info);
                });

                // Araç offline olduğunda
                signalRConnection.on("VehicleOffline", function (vehicleId) {
                    console.log('📴 Vehicle offline:', vehicleId);
                    if (markers[vehicleId]) {
                        markers[vehicleId].setMap(null);
                        delete markers[vehicleId];
                    }
                    if (infoWindows[vehicleId]) {
                        infoWindows[vehicleId].close();
                        delete infoWindows[vehicleId];
                    }
                });

                await signalRConnection.start();
                console.log('✅ SignalR Connected');
            } catch (err) {
                console.error('❌ SignalR Connection Error:', err);
                // 5 saniye sonra tekrar dene
                setTimeout(initSignalR, 5000);
            }
        }

        // Araç marker'ını güncelle veya oluştur
        function updateVehicleMarker(location) {
            const vehicleId = location.vehicleId;
            const lat = location.latitude;
            const lng = location.longitude;
            const status = location.status || 'moving';

            if (markers[vehicleId]) {
                // Mevcut marker'ı güncelle
                const newPosition = { lat: lat, lng: lng };
                markers[vehicleId].setPosition(newPosition);
                
                // Status değişti mi? Marker rengini güncelle
                const newColor = status === 'moving' ? '#28a745' : '#fd7e14';
                markers[vehicleId].setIcon({
                    path: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z',
                    fillColor: newColor,
                    fillOpacity: 1,
                    strokeColor: '#ffffff',
                    strokeWeight: 2,
                    scale: 1.5,
                    anchor: new google.maps.Point(12, 22)
                });
                
                // Takip edilen araçsa kamerayı takip et
                if (followedVehicleId === vehicleId) {
                    map.panTo(newPosition);
                    console.log(`📹 Camera following vehicle ${vehicleId}`);
                }
                
                // InfoWindow içeriğini güncelle (timestamp ve status)
                if (infoWindows[vehicleId]) {
                    const currentContent = infoWindows[vehicleId].getContent();
                    let updatedContent = currentContent
                        .replace(
                            /Son Güncelleme:.*?<\/small>/,
                            `Son Güncelleme: ${new Date(location.timestamp).toLocaleTimeString('tr-TR')}</small>`
                        )
                        .replace(
                            /Durum:<\/strong>.*?<\/p>/s,
                            `Durum:</strong> <span style="color: ${newColor}; font-weight: bold;">${status === 'moving' ? 'Hareket Halinde' : 'Durdu'}</span></small></p>`
                        );
                    infoWindows[vehicleId].setContent(updatedContent);
                }
                
                const statusEmoji = status === 'moving' ? '🚗' : '🛑';
                console.log(`${statusEmoji} Vehicle ${vehicleId} marker updated - Status: ${status}`);
                
                // Sağdaki listeyi güncelle
                updateVehicleListStatus(vehicleId, status);
            } else {
                // Yeni marker oluştur (API'den detay bilgi çek)
                fetchVehicleDetails(vehicleId).then(vehicle => {
                    if (vehicle) {
                        addVehicleMarker(
                            vehicle.id,
                            lat,
                            lng,
                            vehicle.plateNumber || `Araç ${vehicleId}`,
                            vehicle.routeName || 'Bilinmiyor',
                            vehicle.status || 'moving',
                            vehicle.driverName || 'Şoför',
                            vehicle.passengerCount || 0
                        );
                    }
                });
            }
        }
        
        // Sağ taraftaki araç listesindeki durumu güncelle
        function updateVehicleListStatus(vehicleId, status) {
            const vehicleItem = document.querySelector(`.vehicle-item[data-id="${vehicleId}"]`);
            if (vehicleItem) {
                const badge = vehicleItem.querySelector('.vehicle-badge');
                if (badge) {
                    // Eski class'ları temizle
                    badge.classList.remove('badge-success', 'badge-warning', 'bg-success', 'bg-warning');
                    // Yeni class ve renk ekle
                    if (status === 'moving') {
                        badge.classList.add('bg-success');
                        badge.innerHTML = '<i class="bi bi-circle-fill" style="font-size: 10px;"></i> Hareket Halinde';
                    } else {
                        badge.classList.add('bg-warning');
                        badge.innerHTML = '<i class="bi bi-circle-fill" style="font-size: 10px;"></i> Durdu';
                    }
                }
            }
            
            // İstatistikleri güncelle
            updateStatistics();
        }
        
        // İstatistikleri güncelle
        function updateStatistics() {
            let movingCount = 0;
            let stoppedCount = 0;
            
            // Tüm araç badge'lerini kontrol et
            document.querySelectorAll('.vehicle-badge').forEach(badge => {
                if (badge.classList.contains('bg-success')) {
                    movingCount++;
                } else if (badge.classList.contains('bg-warning')) {
                    stoppedCount++;
                }
            });
            
            const totalCount = movingCount + stoppedCount;
            
            // İstatistik label'larını güncelle
            const lblTotal = document.querySelector('#<%= lblTotalVehicles.ClientID %>');
            const lblMoving = document.querySelector('#<%= lblMovingVehicles.ClientID %>');
            const lblStopped = document.querySelector('#<%= lblStoppedVehicles.ClientID %>');
            
            if (lblTotal) lblTotal.textContent = totalCount;
            if (lblMoving) lblMoving.textContent = movingCount;
            if (lblStopped) lblStopped.textContent = stoppedCount;
        }

        // Araç detaylarını API'den çek
        async function fetchVehicleDetails(vehicleId) {
            try {
                const response = await fetch(`${API_BASE_URL}/locations/${vehicleId}`);
                if (response.ok) {
                    return await response.json();
                }
            } catch (err) {
                console.error('Vehicle details fetch error:', err);
            }
            return null;
        }

        window.initMap = function () {
            console.log('🗺️ Google Maps başlatılıyor...');
            console.log('📊 Vehicle data:', vehicleData);
            
            map = new google.maps.Map(document.getElementById('map'), {
                center: { lat: 41.0082, lng: 28.9784 },
                zoom: 12,
                mapTypeControl: true,
                streetViewControl: true,
                fullscreenControl: true
            });

            console.log(`✅ Harita yüklendi, ${vehicleData.length} araç işleniyor...`);

            vehicleData.forEach(function (vehicle) {
                console.log('📍 Marker ekleniyor:', vehicle);
                addVehicleMarker(
                    vehicle.Id,
                    vehicle.Latitude,
                    vehicle.Longitude,
                    vehicle.PlateNumber,
                    vehicle.RouteName,
                    vehicle.Status,
                    vehicle.DriverName,
                    vehicle.PassengerCount
                );
            });

            console.log('✅ Tüm marker\'lar eklendi');

            // SignalR bağlantısını başlat
            initSignalR();
            
            // Her 10 saniyede bir araç durumlarını güncelle
            setInterval(refreshVehicleStatuses, 10000);
        };
        
        // Tüm araçların durumlarını API'den çek ve güncelle
        async function refreshVehicleStatuses() {
            try {
                console.log('🔄 Araç durumları güncelleniyor...');
                const response = await fetch(`${API_BASE_URL}/locations/active`);
                if (response.ok) {
                    const vehicles = await response.json();
                    vehicles.forEach(vehicle => {
                        updateVehicleMarker({
                            vehicleId: vehicle.id,
                            latitude: vehicle.latitude,
                            longitude: vehicle.longitude,
                            status: vehicle.status
                        });
                    });
                    console.log('✅ Araç durumları güncellendi');
                }
            } catch (err) {
                console.error('❌ Araç durumları güncellenirken hata:', err);
            }
        }

        function addVehicleMarker(id, lat, lng, plate, route, status, driver, passengerCount) {
            console.log(`🚗 Marker oluşturuluyor: ${plate} (${lat}, ${lng})`);
            
            const color = status === 'moving' ? '#28a745' : '#fd7e14';

            const marker = new google.maps.Marker({
                position: { lat: lat, lng: lng },
                map: map,
                icon: {
                    path: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z',
                    fillColor: color,
                    fillOpacity: 1,
                    strokeColor: '#ffffff',
                    strokeWeight: 2,
                    scale: 1.5,
                    anchor: new google.maps.Point(12, 22)
                },
                title: plate
            });

            console.log(`✅ Marker eklendi: ${plate}`);

            const infoWindow = new google.maps.InfoWindow({
                content: `
                    <div style="min-width: 220px; padding: 10px;">
                        <h6 style="margin: 0 0 10px 0; color: #2c3e50;">
                            <i class="bi bi-bus-front"></i> ${plate}
                        </h6>
                        <p style="margin: 5px 0;"><small><strong>Rota:</strong> ${route}</small></p>
                        <p style="margin: 5px 0;"><small><strong>Şoför:</strong> ${driver}</small></p>
                        <p style="margin: 5px 0;"><small><strong>Yolcu:</strong> ${passengerCount} kişi</small></p>
                        <p style="margin: 5px 0;"><small><strong>Durum:</strong> 
                            <span style="color: ${color}; font-weight: bold;">
                                ${status === 'moving' ? 'Hareket Halinde' : 'Durdu'}
                            </span>
                        </small></p>
                        <p style="margin: 5px 0;"><small><strong>Son Güncelleme:</strong> ${new Date().toLocaleTimeString('tr-TR')}</small></p>
                    </div>
                `
            });

            marker.addListener('click', function () {
                Object.values(infoWindows).forEach(function (iw) { iw.close(); });
                infoWindow.open(map, marker);
            });

            markers[id] = marker;
            infoWindows[id] = infoWindow;
        }

        window.addEventListener('load', function () {
            document.querySelectorAll('.vehicle-item').forEach(function (item) {
                item.addEventListener('click', function (e) {
                    e.preventDefault();
                    const lat = parseFloat(this.dataset.lat);
                    const lng = parseFloat(this.dataset.lng);
                    const id = parseInt(this.dataset.id);

                    // Takip modunu aktifleştir
                    followedVehicleId = id;
                    console.log(`📌 Now following vehicle ${id}`);

                    if (map) {
                        map.setCenter({ lat: lat, lng: lng });
                        map.setZoom(16);

                        if (markers[id] && infoWindows[id]) {
                            Object.values(infoWindows).forEach(function (iw) { iw.close(); });
                            infoWindows[id].open(map, markers[id]);
                        }
                    }

                    document.querySelectorAll('.vehicle-item').forEach(function (v) { v.classList.remove('active'); });
                    this.classList.add('active');
                });
            });

            const refreshBtn = document.getElementById('refreshBtn');
            if (refreshBtn) {
                refreshBtn.addEventListener('click', function () {
                    location.reload();
                });
            }

            // Auto-refresh kaldırıldı - SignalR gerçek zamanlı güncelleme yapıyor
        });

        // Rota durakları ve yolu haritada göster
        async function loadRouteOnMap(routeId) {
            try {
                const token = '<%= Session["AuthToken"] %>';
                const response = await fetch(`${API_BASE_URL}/api/routes/${routeId}/stops`, {
                    headers: {
                        'Authorization': 'Bearer ' + token
                    }
                });

                if (!response.ok) {
                    console.error('Route stops yüklenemedi:', response.status);
                    return;
                }

                const stops = await response.json();
                console.log('Route stops loaded:', stops);

                if (stops.length === 0) {
                    alert('Bu rotada durak bulunmamaktadır.');
                    return;
                }

                // Eski rota marker'larını temizle
                routeMarkers.forEach(m => m.setMap(null));
                routeMarkers = [];
                if (routePolyline) {
                    routePolyline.setMap(null);
                }

                // Duraklar için marker'lar oluştur
                const bounds = new google.maps.LatLngBounds();
                
                stops.forEach((stop, index) => {
                    const marker = new google.maps.Marker({
                        position: { lat: stop.latitude, lng: stop.longitude },
                        map: map,
                        title: stop.stopName,
                        label: {
                            text: (index + 1).toString(),
                            color: '#ffffff',
                            fontSize: '14px',
                            fontWeight: 'bold'
                        },
                        icon: {
                            path: google.maps.SymbolPath.CIRCLE,
                            scale: 12,
                            fillColor: '#0d6efd',
                            fillOpacity: 1,
                            strokeColor: '#ffffff',
                            strokeWeight: 2
                        }
                    });

                    const infoWindow = new google.maps.InfoWindow({
                        content: `
                            <div style="padding: 8px;">
                                <strong>${index + 1}. ${stop.stopName}</strong><br>
                                <small>Sıra: ${stop.sequenceOrder}</small><br>
                                ${stop.estimatedArrivalTime ? `<small>Tahmini Varış: ${new Date(stop.estimatedArrivalTime).toLocaleTimeString('tr-TR', {hour: '2-digit', minute: '2-digit'})}</small>` : ''}
                            </div>
                        `
                    });

                    marker.addListener('click', () => {
                        infoWindow.open(map, marker);
                    });

                    routeMarkers.push(marker);
                    bounds.extend(marker.getPosition());
                });

                // Polyline çiz
                const path = stops.map(s => ({ lat: s.latitude, lng: s.longitude }));
                routePolyline = new google.maps.Polyline({
                    path: path,
                    strokeColor: '#0d6efd',
                    strokeOpacity: 0.8,
                    strokeWeight: 4,
                    map: map
                });

                // Haritayı tüm durakları içerecek şekilde zoom'la
                map.fitBounds(bounds);

            } catch (error) {
                console.error('Route yükleme hatası:', error);
                alert('Rota yüklenirken hata oluştu: ' + error.message);
            }
        }
    </script>

    <script async defer src="https://maps.googleapis.com/maps/api/js?key=<%= System.Configuration.ConfigurationManager.AppSettings[\"GoogleMapsApiKey\"] %>&callback=initMap&loading=async"></script>
</asp:Content>
