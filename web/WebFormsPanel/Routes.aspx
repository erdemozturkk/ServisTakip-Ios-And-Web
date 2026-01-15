<%@ Page Title="Rotalar" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Routes.aspx.cs" Inherits="WebFormsPanel.Routes" Async="true" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="top-navbar">
        <h2><i class="bi bi-signpost-2"></i> Rotalar</h2>
        <div>
            <button class="btn btn-primary" onclick="window.location.href='CreateRoute.aspx'">
                <i class="bi bi-plus-circle"></i> Yeni Rota Ekle
            </button>
        </div>
    </div>

    <div class="card border-0 shadow-sm">
        <div class="card-body">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th>Rota Adı</th>
                            <th>Araç</th>
                            <th>Şoför</th>
                            <th>Başlangıç</th>
                            <th>Bitiş</th>
                            <th>Durak Sayısı</th>
                            <th>Durum</th>
                            <th>İşlemler</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptRoutes" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td><strong><%# Eval("Name") %></strong></td>
                                    <td><%# Eval("VehiclePlate") %></td>
                                    <td><%# Eval("DriverName") %></td>
                                    <td><%# Eval("StartTime") %></td>
                                    <td><%# Eval("EndTime") %></td>
                                    <td><%# Eval("StopCount") %> durak</td>
                                    <td>
                                        <%# Convert.ToBoolean(Eval("IsActive")) 
                                            ? "<span class='badge bg-success'>Aktif</span>" 
                                            : "<span class='badge bg-secondary'>Pasif</span>" %>
                                    </td>
                                    <td>
                                        <button class="btn btn-sm btn-outline-info" title="Map'te Göster" onclick="showRouteOnMap(<%# Eval("Id") %>)">
                                            <i class="bi bi-geo-alt"></i>
                                        </button>
                                        <button class="btn btn-sm btn-outline-primary" title="Düzenle" onclick="editRoute(<%# Eval("Id") %>)">
                                            <i class="bi bi-pencil"></i>
                                        </button>
                                        <button class="btn btn-sm btn-outline-danger" title="Sil" onclick="deleteRoute(<%# Eval("Id") %>)">
                                            <i class="bi bi-trash"></i>
                                        </button>
                                    </td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>
                        <asp:PlaceHolder ID="phNoRoutes" runat="server" Visible="false">
                            <tr>
                                <td colspan="8" class="text-center text-muted py-5">
                                    <i class="bi bi-inbox" style="font-size: 48px;"></i>
                                    <p class="mt-3">Henüz rota eklenmemiş.</p>
                                </td>
                            </tr>
                        </asp:PlaceHolder>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
        const API_BASE_URL = 'http://localhost:5000';
        const AUTH_TOKEN = '<%= Session["AuthToken"] %>';

        // Map'te rota göster
        function showRouteOnMap(routeId) {
            window.location.href = 'LiveMap.aspx?routeId=' + routeId;
        }

        // Rota düzenle
        function editRoute(routeId) {
            window.location.href = 'CreateRoute.aspx?routeId=' + routeId;
        }

        // Rota sil
        async function deleteRoute(routeId) {
            if (!confirm('Bu rotayı silmek istediğinizden emin misiniz?')) {
                return;
            }

            try {
                const response = await fetch(API_BASE_URL + '/api/routes/' + routeId, {
                    method: 'DELETE',
                    headers: {
                        'Authorization': 'Bearer ' + AUTH_TOKEN
                    }
                });

                if (response.ok) {
                    alert('Rota başarıyla silindi!');
                    location.reload();
                } else {
                    const error = await response.text();
                    alert('Rota silinirken hata oluştu: ' + error);
                }
            } catch (error) {
                console.error('Delete error:', error);
                alert('Rota silinirken hata oluştu: ' + error.message);
            }
        }
    </script>

    <!-- Add Route Modal -->
    <div class="modal fade" id="addRouteModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="bi bi-signpost-2"></i> Yeni Rota Ekle</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Rota Adı</label>
                        <asp:TextBox ID="txtName" runat="server" CssClass="form-control" placeholder="Rota A - Sabah" required="required"></asp:TextBox>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Başlangıç Saati</label>
                        <asp:TextBox ID="txtStartTime" runat="server" CssClass="form-control" TextMode="Time" required="required"></asp:TextBox>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Bitiş Saati</label>
                        <asp:TextBox ID="txtEndTime" runat="server" CssClass="form-control" TextMode="Time" required="required"></asp:TextBox>
                    </div>
                    <div class="mb-3">
                        <div class="form-check">
                            <asp:CheckBox ID="chkIsActive" runat="server" CssClass="form-check-input" Checked="true" />
                            <label class="form-check-label">Aktif</label>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                    <asp:Button ID="btnSaveRoute" runat="server" CssClass="btn btn-primary" Text="Kaydet" OnClick="btnSaveRoute_Click" />
                </div>
            </div>
        </div>
    </div>
</asp:Content>
