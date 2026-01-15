<%@ Page Title="Araçlar" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Vehicles.aspx.cs" Inherits="WebFormsPanel.Vehicles" Async="true" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <asp:Button ID="btnDeleteVehicle" runat="server" OnClick="btnDeleteVehicle_Click" style="display:none;" />
    <asp:HiddenField ID="hfEditVehicleId" runat="server" Value="0" />
    
    <div class="top-navbar">
        <h2><i class="bi bi-bus-front"></i> Araçlar</h2>
        <div>
            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#vehicleModal">
                <i class="bi bi-plus-circle"></i> Yeni Araç Ekle
            </button>
        </div>
    </div>

    <div class="card border-0 shadow-sm">
        <div class="card-body">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th>Plaka</th>
                            <th>Model</th>
                            <th>Kapasite</th>
                            <th>Durum</th>
                            <th>Şoför</th>
                            <th>İşlemler</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptVehicles" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td><strong><%# Eval("Plate") %></strong></td>
                                    <td><%# Eval("Model") %></td>
                                    <td><%# Eval("Capacity") %> kişi</td>
                                    <td>
                                        <%# Convert.ToBoolean(Eval("IsActive")) 
                                            ? "<span class='badge bg-success'>Aktif</span>" 
                                            : "<span class='badge bg-secondary'>Pasif</span>" %>
                                    </td>
                                    <td><%# Eval("DriverName") != null ? Eval("DriverName") : "-" %></td>
                                    <td>
                                        <button type="button" class="btn btn-sm btn-outline-primary" title="Düzenle" onclick="editVehicle(<%# Eval("Id") %>, '<%# Eval("Plate") %>', '<%# Eval("Model") %>', <%# Eval("Capacity") %>, <%# Eval("IsActive").ToString().ToLower() %>)">
                                            <i class="bi bi-pencil"></i>
                                        </button>
                                        <button type="button" class="btn btn-sm btn-outline-danger" title="Sil" onclick="deleteVehicle(<%# Eval("Id") %>, '<%# Eval("Plate") %>')">
                                            <i class="bi bi-trash"></i>
                                        </button>
                                    </td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>
                        <asp:PlaceHolder ID="phNoVehicles" runat="server" Visible="false">
                            <tr>
                                <td colspan="7" class="text-center text-muted py-5">
                                    <i class="bi bi-inbox" style="font-size: 48px;"></i>
                                    <p class="mt-3">Henüz araç eklenmemiş.</p>
                                </td>
                            </tr>
                        </asp:PlaceHolder>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Add Vehicle Modal -->
    <div class="modal fade" id="vehicleModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="bi bi-bus-front"></i> Yeni Araç Ekle</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Plaka</label>
                        <asp:TextBox ID="txtPlateNumber" runat="server" CssClass="form-control" placeholder="34 ABC 123" required="required"></asp:TextBox>
                    </div>
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Marka</label>
                            <asp:TextBox ID="txtBrand" runat="server" CssClass="form-control" placeholder="Mercedes" required="required"></asp:TextBox>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Model</label>
                            <asp:TextBox ID="txtModel" runat="server" CssClass="form-control" placeholder="Sprinter" required="required"></asp:TextBox>
                        </div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Kapasite</label>
                        <asp:TextBox ID="txtCapacity" runat="server" CssClass="form-control" TextMode="Number" placeholder="20" required="required"></asp:TextBox>
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
                    <asp:Button ID="btnSaveVehicle" runat="server" CssClass="btn btn-primary" Text="Kaydet" OnClick="btnSaveVehicle_Click" />
                </div>
            </div>
        </div>
    </div>

    <script>
        function editVehicle(id, plate, model, capacity, isActive) {
            // Hidden field'a ID'yi kaydet
            document.getElementById('<%= hfEditVehicleId.ClientID %>').value = id;
            
            // Model'i marka ve model olarak ayır
            const modelParts = model.split(' ');
            const brand = modelParts[0] || '';
            const modelName = modelParts.slice(1).join(' ') || '';
            
            // Form alanlarını doldur
            document.getElementById('<%= txtPlateNumber.ClientID %>').value = plate;
            document.getElementById('<%= txtBrand.ClientID %>').value = brand;
            document.getElementById('<%= txtModel.ClientID %>').value = modelName;
            document.getElementById('<%= txtCapacity.ClientID %>').value = capacity;
            document.getElementById('<%= chkIsActive.ClientID %>').checked = isActive;
            
            // Modal başlığını güncelle
            document.querySelector('#vehicleModal .modal-title').textContent = 'Araç Düzenle';
            document.getElementById('<%= btnSaveVehicle.ClientID %>').textContent = 'Güncelle';
            
            // Modal'ı aç
            const modal = new bootstrap.Modal(document.getElementById('vehicleModal'));
            modal.show();
        }

        function deleteVehicle(id, plate) {
            if (confirm(`"${plate}" plakalı aracı silmek istediğinizden emin misiniz?`)) {
                // Hidden field'a ID'yi kaydet
                document.getElementById('<%= hfEditVehicleId.ClientID %>').value = id;
                
                // Delete işlemini trigger et
                <%= ClientScript.GetPostBackEventReference(btnDeleteVehicle, "") %>;
            }
        }

        // Modal kapandığında formu temizle
        document.getElementById('vehicleModal').addEventListener('hidden.bs.modal', function () {
            document.getElementById('<%= hfEditVehicleId.ClientID %>').value = '0';
            document.getElementById('<%= txtPlateNumber.ClientID %>').value = '';
            document.getElementById('<%= txtBrand.ClientID %>').value = '';
            document.getElementById('<%= txtModel.ClientID %>').value = '';
            document.getElementById('<%= txtCapacity.ClientID %>').value = '';
            document.getElementById('<%= chkIsActive.ClientID %>').checked = true;
            document.querySelector('#vehicleModal .modal-title').textContent = 'Yeni Araç Ekle';
            document.getElementById('<%= btnSaveVehicle.ClientID %>').textContent = 'Kaydet';
        });
    </script>
</asp:Content>
