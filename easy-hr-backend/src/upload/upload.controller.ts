import { Controller, Post, UseGuards, Request, UseInterceptors, UploadedFile, BadRequestException, Query } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes, ApiBody } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SupabaseService } from '../supabase/supabase.service';
import { v4 as uuidv4 } from 'uuid';

@ApiTags('Upload')
@Controller('upload')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class UploadController {
  constructor(private supabaseService: SupabaseService) {}

  @Post()
  @ApiOperation({ summary: 'Upload a file (photo, document)' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'object', properties: { file: { type: 'string', format: 'binary' } } } })
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 10 * 1024 * 1024 } }))
  async uploadFile(
    @UploadedFile() file: Express.Multer.File,
    @Request() req,
    @Query('folder') folder?: string,
  ) {
    if (!file) throw new BadRequestException('No file uploaded');

    const ext = file.originalname.split('.').pop()?.toLowerCase() || 'jpg';
    const allowedExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'doc', 'docx'];
    if (!allowedExts.includes(ext)) {
      throw new BadRequestException('File type not allowed');
    }

    const subfolder = folder || 'general';
    const fileName = `${subfolder}/${req.user.company_id}/${uuidv4()}.${ext}`;

    const db = this.supabaseService.getClient();
    const { data, error } = await db.storage
      .from('uploads')
      .upload(fileName, file.buffer, {
        contentType: file.mimetype,
        upsert: false,
      });

    if (error) {
      console.error('Upload error:', error);
      throw new BadRequestException('Failed to upload file: ' + error.message);
    }

    const { data: urlData } = db.storage.from('uploads').getPublicUrl(data.path);

    return {
      url: urlData.publicUrl,
      path: data.path,
      filename: file.originalname,
      size: file.size,
      mimetype: file.mimetype,
    };
  }
}
