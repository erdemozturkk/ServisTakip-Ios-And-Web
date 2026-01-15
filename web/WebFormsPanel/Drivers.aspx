<%@ Page Title="Şoförler" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Drivers.aspx.cs" Inherits="WebFormsPanel.Drivers" Async="true" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <asp:Button ID="btnDeleteDriver" runat="server" OnClick="btnDeleteDriver_Click" style="display:none;" />
    <asp:HiddenField ID="hfEditDriverId" runat="server" Value="0" />
    
    <div class="top-navbar">
        <h2><i class="bi bi-person-badge"></i> Şoförler</h2>
        <div>
            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#driverModal">
                <i class="bi bi-plus-circle"></i> Yeni Şoför Ekle
            </button>
        </div>
    </div>

    <div class="card border-0 shadow-sm">
        <div class="card-body">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th>Ad Soyad</th>
                            <th>Telefon</th>
                            <th>Email</th>
                            <th>Atanmış Araç</th>
                            <th>Durum</th>
                            <th>İşlemler</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptDrivers" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td><strong><%# Eval("Name") %></strong></td>
                                    <td><%# Eval("PhoneNumber") %></td>
                                    <td><%# Eval("Email") %></td>
                                    <td><%# Eval("AssignedVehicle") != null ? Eval("AssignedVehicle") : "-" %></td>
                                    <td>
                                        <%# Convert.ToBoolean(Eval("IsActive")) 
                                            ? "<span class='badge bg-success'>Aktif</span>" 
                                            : "<span class='badge bg-secondary'>Pasif</span>" %>
                                    </td>
                                    <td>
                                        <button type="button" class="btn btn-sm btn-outline-primary" title="Düzenle" 
                                                data-id="<%# Eval("Id") %>" 
                                                data-name="<%# Eval("Name") %>" 
                                                data-email="<%# Eval("Email") %>" 
                                                data-phone="<%# Eval("PhoneNumber") %>"
                                                onclick="editDriverFromData(this)">
                                            <i class="bi bi-pencil"></i>
                                        </button>
                                        <button type="button" class="btn btn-sm btn-outline-danger" title="Sil" 
                                                data-id="<%# Eval("Id") %>" 
                                                data-name="<%# Eval("Name") %>"
                                                onclick="deleteDriverFromData(this)">
                                            <i class="bi bi-trash"></i>
                                        </button>
                                    </td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>
                        <asp:PlaceHolder ID="phNoDrivers" runat="server" Visible="false">
                            <tr>
                                <td colspan="7" class="text-center text-muted py-5">
                                    <i class="bi bi-inbox" style="font-size: 48px;"></i>
                                    <p class="mt-3">Henüz şoför eklenmemiş.</p>
                                </td>
                            </tr>
                        </asp:PlaceHolder>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Add/Edit Driver Modal -->
    <div class="modal fade" id="driverModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="bi bi-person-badge"></i> Yeni Şoför Ekle</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Ad Soyad</label>
                        <asp:TextBox ID="txtName" runat="server" CssClass="form-control" required="required"></asp:TextBox>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Email</label>
                        <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control" TextMode="Email" required="required"></asp:TextBox>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Telefon</label>
                        <asp:TextBox ID="txtPhoneNumber" runat="server" CssClass="form-control" placeholder="0532 123 4567"></asp:TextBox>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Atanacak Araç</label>
                        <asp:DropDownList ID="ddlVehicle" runat="server" CssClass="form-control">
                            <asp:ListItem Value="0" Text="Araç seçiniz (opsiyonel)"></asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                    <asp:Button ID="btnSaveDriver" runat="server" CssClass="btn btn-primary" Text="Kaydet" OnClick="btnSaveDriver_Click" />
                </div>
            </div>
        </div>
    </div>

    <script>
        function editDriverFromData(button) {
            const id = button.getAttribute('data-id');
            const name = button.getAttribute('data-name');
            const email = button.getAttribute('data-email');
            const phone = button.getAttribute('data-phone');
            
            document.getElementById('<%= hfEditDriverId.ClientID %>').value = id;
            document.getElementById('<%= txtName.ClientID %>').value = name;
            document.getElementById('<%= txtEmail.ClientID %>').value = email;
            document.getElementById('<%= txtPhoneNumber.ClientID %>').value = phone || '';
            document.getElementById('<%= ddlVehicle.ClientID %>').value = '0';
            
            document.querySelector('#driverModal .modal-title').textContent = 'Şoför Düzenle';
            document.getElementById('<%= btnSaveDriver.ClientID %>').textContent = 'Güncelle';
            
            const modal = new bootstrap.Modal(document.getElementById('driverModal'));
            modal.show();
        }

        function deleteDriverFromData(button) {
            const id = button.getAttribute('data-id');
            const name = button.getAttribute('data-name');
            
            if (confirm(`"${name}" isimli şoförü silmek istediğinizden emin misiniz?`)) {
                document.getElementById('<%= hfEditDriverId.ClientID %>').value = id;
                <%= ClientScript.GetPostBackEventReference(btnDeleteDriver, "") %>;
            }
        }

        document.getElementById('driverModal').addEventListener('hidden.bs.modal', function () {
            document.getElementById('<%= hfEditDriverId.ClientID %>').value = '0';
            document.getElementById('<%= txtName.ClientID %>').value = '';
            document.getElementById('<%= txtEmail.ClientID %>').value = '';
            document.getElementById('<%= txtPhoneNumber.ClientID %>').value = '';
            document.getElementById('<%= ddlVehicle.ClientID %>').value = '0';
            document.querySelector('#driverModal .modal-title').textContent = 'Yeni Şoför Ekle';
            document.getElementById('<%= btnSaveDriver.ClientID %>').textContent = 'Kaydet';
        });
    </script>
</asp:Content>
