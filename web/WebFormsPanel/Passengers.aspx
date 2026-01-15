<%@ Page Title="Yolcular" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Passengers.aspx.cs" Inherits="WebFormsPanel.Passengers" Async="true" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="top-navbar">
        <h2><i class="bi bi-people"></i> Yolcular</h2>
        <div>
            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addPassengerModal">
                <i class="bi bi-plus-circle"></i> Yeni Yolcu Ekle
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
                            <th>Adres</th>
                            <th>Atanmış Rota</th>
                            <th>Durum</th>
                            <th>İşlemler</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptPassengers" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td><strong><%# Eval("Name") %></strong></td>
                                    <td><%# Eval("PhoneNumber") %></td>
                                    <td><%# Eval("Email") %></td>
                                    <td><%# Eval("Address") %></td>
                                    <td><%# Eval("AssignedRoute") != null ? Eval("AssignedRoute") : "-" %></td>
                                    <td>
                                        <%# Convert.ToBoolean(Eval("IsActive")) 
                                            ? "<span class='badge bg-success'>Aktif</span>" 
                                            : "<span class='badge bg-secondary'>Pasif</span>" %>
                                    </td>
                                    <td>
                                        <button class="btn btn-sm btn-outline-primary" title="Düzenle">
                                            <i class="bi bi-pencil"></i>
                                        </button>
                                        <button class="btn btn-sm btn-outline-danger" title="Sil">
                                            <i class="bi bi-trash"></i>
                                        </button>
                                    </td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>
                        <asp:PlaceHolder ID="phNoPassengers" runat="server" Visible="false">
                            <tr>
                                <td colspan="7" class="text-center text-muted py-5">
                                    <i class="bi bi-inbox" style="font-size: 48px;"></i>
                                    <p class="mt-3">Henüz yolcu eklenmemiş.</p>
                                </td>
                            </tr>
                        </asp:PlaceHolder>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Add Passenger Modal -->
    <div class="modal fade" id="addPassengerModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="bi bi-people"></i> Yeni Yolcu Ekle</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Ad Soyad</label>
                        <asp:TextBox ID="txtName" runat="server" CssClass="form-control" required="required"></asp:TextBox>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Telefon</label>
                        <asp:TextBox ID="txtPhoneNumber" runat="server" CssClass="form-control" placeholder="0532 123 4567" required="required"></asp:TextBox>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Email</label>
                        <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control" TextMode="Email" required="required"></asp:TextBox>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Adres</label>
                        <asp:TextBox ID="txtAddress" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" required="required"></asp:TextBox>
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
                    <asp:Button ID="btnSavePassenger" runat="server" CssClass="btn btn-primary" Text="Kaydet" OnClick="btnSavePassenger_Click" />
                </div>
            </div>
        </div>
    </div>
</asp:Content>
