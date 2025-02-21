class AttachmentsController < ApplicationController
  load_and_authorize_resource
  skip_load_and_authorize_resource :only => [:create, :show]
  before_action :load_attachment, except: [:index, :create]
  before_action :authenticate_user!

  def index
    respond_to do |format|
      @attachment = Attachment.new
      
      format.html do
        @policies = Policy.all.where(is_published: true)
        @company_docs = Attachment.company_documents.where(is_visible_to_all: true)
      end

      format.js do
        if params.has_key?(:all_policies)
          @policies = if params[:all_policies] == "true"      
            Policy.all 
          else
            Policy.all.where(is_published: true)
          end
        end  
        
        if params.has_key?(:all_docs)
          @company_docs =  if params[:all_docs] == "true"
            Attachment.company_documents
          else
            Attachment.company_documents.where(is_visible_to_all: true)
          end 
        end
      end

      format.json { render json: @company_docs.to_json } 
    end
  end

  def create
    @attachment = Attachment.new(attachment_params)
    if @attachment.save
      flash[:notice] = 'Document saved successfully'
    else
      flash[:error] = @attachment.errors.full_messages.try(:join, ', ')
    end
    redirect_to attachments_path
  end

  def update
    if @attachment.update_attributes(attachment_params)
      flash[:notice] = "Document updated successfully"
    else
      flash[:error] = "Failed to save document"
    end
    redirect_to attachments_path
  end

  def destroy
    flash[:notice] = @attachment.destroy ? "Document deleted Successfully" : "Error in deleting document"
    redirect_to attachments_path
  end

  def download_document
    document = @attachment.document
    document_type = MIME::Types.type_for(document.url).first.content_type
    document_extension = '.' + document.file.extension.downcase
    send_file document.path, filename: document.model.name + document_extension, type: "#{document_type}"
  end

  private
  def load_attachment
    @attachment = Attachment.find(params[:id])
  end

  def attachment_params
    params.require(:attachment).permit(:name, :document, :document_type, :is_visible_to_all)
  end
end
